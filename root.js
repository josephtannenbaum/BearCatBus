angular.module('root', ['schedules', 'ui.select2'])
	.run(['uiSelect2Config', function(uiSelect2Config) {
    	uiSelect2Config.allowClear = true;
}])
	.controller('timetable', ['$scope', '$interval', '$http', 'aliasesParser', 'scheduleParser', 'departTimeFilter',
		function($scope, $interval, $http, aliasesParser, scheduleParser, departTimeFilter) {
			

			$scope.selectBus = function(bus) {
				$scope.selectedBus = bus;
			}
			$scope.selectStop = function(stop) {
				$scope.selectedLoc = stop;
			}

			$scope.saveDefault = function() {
				var data = {selectedBus: $scope.selectedBus,
							selectedLoc: $scope.selectedLoc}
				localStorage	.userService = angular.toJson(data)
				$("#saveDefault").text("Saved!")
				console.log("Saved default options")
			}

			$scope.stopNames = $scope.aliases = $scope.fullTimetable = [];
			$scope.ones = [];
			$scope.now = moment();
			$scope.msg = {s: 'Loading timetable...'};
			window.statusMessage = 'Loading bus schedule...';
			$http.get('aliases.json').success(function(data){
				$scope.aliases = aliasesParser(data);
				$scope.busCodes = [];
				for (var i = 0; i < $scope.aliases.length; i++) {
					$scope.busCodes.push($scope.aliases[i].busCode.toLowerCase());
				};
			});
			$http.get('schedules.json').success(function(data){
				$scope.stopNames = Object.keys(data);
				$scope.fullTimetable = scheduleParser(data);
				$scope.msg.s = '';
			});

			userDefaults = angular.fromJson(localStorage.userService);
			if(userDefaults) {
				if('selectedBus' in userDefaults)
					$scope.selectedBus = userDefaults.selectedBus;
				if('selectedLoc' in userDefaults)
					$scope.selectedLoc = userDefaults.selectedLoc;
			}

			stopTime = $interval( function() {
				$scope.now = moment();
				$scope.ones = departTimeFilter($scope.now)($scope.fullTimetable);
			}, 1000);

			$scope.impendingDeparture = function(departTime) {
				return departTime - ($scope.now.hours()*60 + $scope.now.minutes()) < 6;
			}

			resetSaveButton = function() {
				$("#saveDefault").text("Save as default")
			}
			$scope.$watch('selectedBus', resetSaveButton);
			$scope.$watch('selectedLoc', resetSaveButton);
}]);


$(document).ready(function(){
	$("#aboutButton").leanModal({ top : 200, overlay : 0.1, closeButton: ".modal_close" });
});