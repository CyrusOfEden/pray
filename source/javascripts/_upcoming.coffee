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
    constructor: (@name, @after, @before, @points, @offset) ->
      @after = new Date clean(@after) + offset * 24 * 60 * 60 * 1000
      @before = new Date clean(@before) + offset * 24 * 60 * 60 * 1000

    current: -> @after < new Date() < @before
    past: -> @after < new Date()


  # Initialize
  # ==========
  $scope.start = ->
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
      .then -> $scope.ready = true


  $scope.init = ->
    moments = [
                ["fajr", "sunrise"],
                ["zuhr", "asr"],
                ["asr", "maghrib"],
                ["maghrib", "isha"],
                ["isha", "midnight"]
              ]
    days =
      for day in ["today", "tomorrow"]
        for points in moments
          name = (if points[0] == "fajr" then "sobh" else points[0])
          after = $scope[day][points[0]]
          before = $scope[day][points[1]]
          offset = (if day == "today" then 0 else 1)
          prayer = new Prayer name, after, before, points, offset

    prayers = [].concat.apply([], days)
    current = do ->
      now = next = null
      for num in [0..9]
        if prayers[num].current()
          now = num
          break
        if prayers[num].past()
          next ||= num + 1
      now || next

    $scope.prayers = prayers.splice current, 5



  $scope.update = ->
    # Get the timezone
    $scope.timezone = -Math.abs new Date().getTimezoneOffset() / 60
    # Set today
    today = new Date()
    # Get prayer times
    $scope.today = PrayTimes.getTimes today, $scope.location, $scope.timezone
    # Set tomorrow
    tomorrow = new Date today.getTime() + 24 * 60 * 60 * 1000
    # Get tomorrow's times
    $scope.tomorrow = PrayTimes.getTimes tomorrow, $scope.location, $scope.timezone
    # Compensate for varying midnight times
    $scope.today.midnight = $scope.tomorrow.midnight = "24:00"



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