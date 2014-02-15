app = angular.module "Pray", []

app.controller "AppCtrl",
['$scope', '$filter', '$interval', ($scope, $filter, $interval) ->

  # Extending functions
  # ===================
  String::capitalize = ->
    @charAt(0).toUpperCase() + @slice 1


  clean = (time) ->
    time = time.split ":"
    new Date().setHours time[0], time[1], 0, 0


  moments = [
              ["fajr", "sunrise"],
              ["zuhr", "asr"],
              ["asr", "maghrib"],
              ["maghrib", "isha"],
              ["isha", "midnight"]
            ]


  class Prayer
    constructor: (@name, @after, @before, @points) ->
      @after = new Date clean @after
      @before = new Date clean @before

    current: ->
      if @after < new Date() < @before then true else false


  # Initialize
  # ==========
  $scope.init = ->
    # Configuration variables
    # =======================
    $scope.now = new Date()
    $scope.location = [43.84, -79.47]
    $scope.timezone = -Math.abs new Date().getTimezoneOffset() / 60

    # Get prayer times
    $scope.update()

    $scope.prayers = do ->
      for points in moments
        name = (if points[0] == "fajr" then "sobh" else points[0])
        after = $scope.times[points[0]]
        before = $scope.times[points[1]]
        new Prayer(name, after, before, points)

    $interval ->
      $scope.update true
    , 30000


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


  $scope.relative = (prayer) ->
    filter = (time) -> $filter("date")(time, "h:mma").toLowerCase()
    if prayer.current()
      "by #{filter(prayer.before)}."
    else
      "between #{filter(prayer.after)} and #{filter(prayer.before)}."


]