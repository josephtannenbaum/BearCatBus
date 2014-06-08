aliases = [];
stops = [];
parsed(occt, aliases, stops);
console.log(stops);

angular.module('root', [])
	.controller('index', ['$scope', function($scope) {
		$scope.buses = [
			{id: 'WS', name: 'Westside'},
			{id: 'LRS', name: 'Leroy'},
			{id: 'DCR', name: 'Downtown'},
			{id: 'CS', name: 'Campus'}
		];
}]);

