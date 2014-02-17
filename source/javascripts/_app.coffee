app = angular.module "Pray", []

app.controller "AppCtrl",
['$scope', '$filter', '$timeout', '$interval',
($scope, $filter, $timeout, $interval) ->

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
    constructor: (@name, @after, @before, @points, @done) ->
      @after = new Date clean @after
      @before = new Date clean @before
      @done = false

    current: ->
      if @after < $scope.now < @before then true else false

    checkin: ->
      @done = !@done


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
        prayer = new Prayer(name, after, before, points, false)

    for prayer in $scope.prayers
      $scope.current = prayer if prayer.current()

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
        $scope.current = prayer if prayer.current()


  $scope.relative = (prayer) ->
    filter = (time) -> $filter("date")(time, "h:mma").toLowerCase()
    if prayer.current()
      "by #{filter(prayer.before)}."
    else
      "between #{filter(prayer.after)} and #{filter(prayer.before)}."


  $scope.direction = ->
    kaaba = 0;
    {
      "-webkit-transform": "rotate(#{kaaba - 90}deg)",
      "-moz-transform": "rotate(#{kaaba - 90}deg)",
      "-ms-transform": "rotate(#{kaaba - 90}deg)",
      "-o-transform": "rotate(#{kaaba - 90}deg)",
      "transform": "rotate(#{kaaba - 90}deg)"
    }


]