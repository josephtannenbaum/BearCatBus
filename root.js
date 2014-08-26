angular.module('root', ['schedules', 'ui.select2'])
	.run(['uiSelect2Config', function(uiSelect2Config) {
    	uiSelect2Config.allowClear = true;
}])
	.controller('timetable', ['$scope', '$interval', '$http', 'aliasesParser', 'scheduleParser', 'departTimeFilter',
		function($scope, $interval, $http, aliasesParser, scheduleParser, departTimeFilter) {
			$scope.t = {};
			var route_colors = {};

			// saves currently selected bus stop and/or bus route to local storage
			$scope.saveDefault = function() {
				localStorage.userService = angular.toJson({selectedBus: $scope.t.selectedBus,
															selectedLoc: $scope.t.selectedLoc})
				$("#saveDefault").text("Saved!")
			}

			$scope.stopNames = $scope.aliases = $scope.fullTimetable = $scope.ones = [];
			$scope.now = moment();
			$scope.msg = {s: 'Loading timetable...'};
			window.statusMessage = 'Loading bus schedule...';
			
			// load the misc data that helps the UI
			$http.get('extradata-wbw.json').success(function(data){
				$scope.aliases = aliasesParser(data['aliases']);
				$scope.busCodes = [];
				route_colors = data['route_colors']
				for (var i = 0; i < $scope.aliases.length; i++) {
					$scope.busCodes.push($scope.aliases[i].busCode.toLowerCase());
				};
				$scope.stopGroupings = invertObj(data['groupings']);
			});

			// load the schedule file
			$http.get('schedules-wbw.json').success(function(data){
				$scope.stopNames = Object.keys(data);
				$scope.fullTimetable = scheduleParser(data);
				$scope.msg.s = '';
			});

			// check for default bus stop and/or bus route in local storage
			userDefaults = angular.fromJson(localStorage.userService);
			if(userDefaults) {
				if('selectedBus' in userDefaults)
					$scope.t.selectedBus = userDefaults.selectedBus;
				if('selectedLoc' in userDefaults)
					$scope.t.selectedLoc = userDefaults.selectedLoc;
			}

			// update timetable every second
			stopTime = $interval( function() {
				$scope.now = moment();
				if ($scope.showFullTimetable) {
					$scope.ones = $scope.fullTimetable;
				} else {
					$scope.ones = departTimeFilter($scope.now)($scope.fullTimetable);
				}
			}, 1000);

			// for the view: know when a time (# of minutes passed 00:00) is within five minutes 
			$scope.impendingDeparture = function(departTime) {
				if ($scope.showFullTimetable) return false;
				return departTime - ($scope.now.hours()*60 + $scope.now.minutes()) < 6;
			}

			$scope.fromNow = function(s) {
				return moment(s,"h:mm A").fromNow()
			}

			// Resetting save button on blur
			resetSaveButton = function() {
				$("#saveDefault").text("Save as default");
			}
			$scope.$watch('t.selectedBus', resetSaveButton);
			$scope.$watch('t.selectedLoc', resetSaveButton);

			// Route map UI
			$scope.showRouteMap = false
			updateRouteMap = function() {
				if ($scope.showRouteMap) {
					$("#routeMap").html(window.mapiframes[$scope.t.selectedBus]);
				}
			}
			$scope.toggleRouteMap = function() {
				$scope.showRouteMap = !$scope.showRouteMap
				if ($scope.showRouteMap) {
					$("#toggleRouteMap").text("Hide route map");
					updateRouteMap();
				} else
					$("#toggleRouteMap").text("Show route map");
			}
			$scope.$watch('t.selectedBus', updateRouteMap);

			$scope.busCodeStyle = function(code) {
				return {'background': route_colors[code.toUpperCase()]}
			};

}]);


$(document).ready(function(){
	$("#aboutButton").leanModal({ top : 200, overlay : 0.1, closeButton: ".modal_close" });
});