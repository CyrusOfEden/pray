app = angular.module "Pray", []

app.controller "AppCtrl",
['$scope', '$filter', '$q', '$interval',
($scope, $filter, $q, $interval) ->

  # Extending functions
  # ===================
  String::capitalize = ->
    @charAt(0).toUpperCase() + @slice 1


  clean = (time) ->
    time = time.split ":"
    new Date().setHours time[0], time[1], 0, 0


  class Prayer
    constructor: (@name, @after, @before, @points) ->
      @after = new Date clean @after
      @before = new Date clean @before

    current: ->
      if @after < $scope.now < @before then true else false


  # Initialize
  # ==========
  $scope.start = ->
    # Configuration variables
    $scope.now = new Date()
    $scope.timezone = -(Math.abs(new Date().getTimezoneOffset() / 60))

    defer = $q.defer()
    navigator.geolocation.watchPosition (position) ->
      latitude = Number position.coords.latitude.toFixed 3
      longitude = Number position.coords.longitude.toFixed 3
      heading = position.coords.heading || 0

      $scope.location = [latitude, longitude, heading]

      rad = (number) -> number * (Math.PI / 180)
      deg = (number) -> number * (180 / Math.PI)

      location = [rad(latitude), rad(longitude)]
      kaaba = [rad(21.423), rad(39.826)]
      delta = [location[0] - kaaba[0], location[1] - kaaba[1]]

      y = Math.sin(delta[1]) * Math.cos(location[0])
      x = Math.cos(kaaba[0]) * Math.sin(location[0]) -
          Math.sin(kaaba[0]) * Math.cos(location[0]) * Math.cos(delta[1])
      $scope.direction = 360 - (deg(Math.atan2(y, x)) + 360) % 360

      defer.resolve()

    defer.promise
      .then $scope.update
      .then $scope.init
      .then $scope.point


  $scope.init = ->
    moments = [
                ["fajr", "sunrise"],
                ["zuhr", "asr"],
                ["asr", "maghrib"],
                ["maghrib", "isha"],
                ["isha", "midnight"]
              ]
    $scope.prayers = do ->
      for points in moments
        name = (if points[0] == "fajr" then "sobh" else points[0])
        after = $scope.times[points[0]]
        before = $scope.times[points[1]]
        prayer = new Prayer name, after, before, points


  $scope.update = (set = false) ->
    # Get prayer times
    $scope.times = PrayTimes.getTimes $scope.now, $scope.location, $scope.timezone
    # Compensate for varying midnight times
    $scope.times.midnight = "24:00"

    # Update prayers
    if set
      for prayer in $scope.prayers
        prayer.after = new Date clean $scope.times[prayer.points[0]]
        prayer.before = new Date clean $scope.times[prayer.points[1]]
        $scope.current = prayer if prayer.current()


  $scope.relative = (prayer) ->
    filter = (time) -> $filter("date")(time, "h:mma").toLowerCase()
    if prayer.current()
      "by #{filter(prayer.before)}."
    else
      "between #{filter(prayer.after)} and #{filter(prayer.before)}."


  $scope.point = ->
    direction = $scope.direction - $scope.location[2] - 90
    $scope.bearing = {
      "-webkit-transform": "rotate(#{direction}deg)",
      "-moz-transform": "rotate(#{direction}deg)",
      "-ms-transform": "rotate(#{direction}deg)",
      "-o-transform": "rotate(#{direction}deg)",
      "transform": "rotate(#{direction}deg)"
    }


]