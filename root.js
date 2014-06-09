var now_ones = [];
angular.module('root', [])
	.controller('onelist', ['$scope', function($scope) {
		$scope.$watch("location", function (newValue) {
			$scope.ones = filter_by_location(now_ones, newValue);
		});
		now_ones = filter_by_time(ones, moment().hour()*60 + moment().minute(), moment().isoWeekday()-1)
		$scope.ones = now_ones;
}])
	.directive('now', function($interval) {
		return function(scope, element, attrs) {
			var format, stopTime;
			function updateTime() {
          		element.text(moment().format("dddd, MMMM Do, h:mm:ss a"));
          		now_ones = filter_by_time(ones, moment().hour()*60 + moment().minute(), moment().isoWeekday()-1)
        	}
        	updateTime();
        	stopTime = $interval(updateTime, 1000);
        	element.on('$destroy', function() {
        		$interval.cancel(stopTime);
        	});
        };
});
