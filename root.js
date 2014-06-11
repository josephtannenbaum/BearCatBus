angular.module('root', ['schedules'])
	.controller('timetable', ['$scope', '$interval','$http', 'aliasesParser', 'scheduleParser', 
		function($scope, $interval, $http, aliasesParser, scheduleParser) {
			$scope.stopNames = $scope.aliases = $scope.ones = [];
			$scope.now = moment();
			$http.get('aliases.json').success(function(data){
				$scope.aliases = aliasesParser(data);
			});
			$http({method: 'GET', url: 'schedules.json', cache: true}).success(function(data){
				$scope.stopNames = Object.keys(data);
				$scope.ones = scheduleParser(data);
			});
			function updateTime() {
				newtime = moment();
				if (newtime.isAfter($scope.now, 'minute'))
					$scope.now = moment();
			}
			stopTime = $interval(updateTime, 1000);
}]);
