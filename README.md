# Dart/Flutter version of Missile Site Demo

Missile Site using [Rocket lib](/docs/rocket-lib/api/index.html) which uses [SAMCAS](/docs/samcas/api/index.html) library as its engine.

## Description

This app implements in Dart using the Flutter platform a demonstration of combining many [SAMCAS](/docs/samcas/api/index.html) models
into a working app. It demonstrates the *SAM* pattern proposed by
[Jean-Jacques Dubray](https://www.infoq.com/profile/Jean~Jacques-Dubray) and explained at
[sam.js.org](https://sam.js.org/).

*SAM* (State-Action-Model) is a software engineering pattern that helps manage the application state and reason about temporal aspects with precision and clarity.
In brief, it provides a robust pattern with which to organize complex state mutations found in modern applications.

The Dart version of [SAMCAS](/docs/samcas/api/index.html) is a table driven approach to the *SAM* pattern and extends the *SAM* pattern
by including a simple signal protocol for child models to inform their parents of their state changes.

This app demonstrates:

1. Many [SamModel]s interacting together (parent to child and child to parent).

2. More complex widget build structures

3. Use of [Navigator] component to change pages

3. State transitions for the [Site] itself as well as the children

4. Flutter screen size dependent layout

5. Logging window


The source code available at [missile-dart-app](https://github/srp7474/missile-dart-app) along with these documents
can be used as a road map to build a [SAMCAS](/docs/samcas/api/index.html) application.

The companion [Rocket](../../rocket/api/index.html) is a simpler application incorporating
the [SAMCAS](/docs/samcas/api/index.html) facility into a Flutter app.


## How to Use

1. You are asked to define the Missile Site. Just pressing  the `BUILD` button will build an unnamed default site.
Giving the site a name or varying the number of banks will cause the site to be built according to the non-default
values.

2. You will see one or more **Banks**. Start the missile in each.

3. Turning on the **Auto Mode** switch will display the `Incoming` button. Pressing this will launch all available missiless with a delay in between.
You will also be asked to choose a delay time (10, 15, 20) seconds.

4. When all the missiles are used in a bank it will be marked **DEPLETED**. Pressing the `Replenish` button will replenish the site.

5. When there is only 1 bank left the site will enter a blinking **Distressed** state.

6. When there are no Banks left the site will enter a **Defunct** state.

## License

**Copyright (c) 2020 Steve Pritchard of Rexcel Systems Inc.**

Released under the [The MIT License](https://opensource.org/licenses/MIT)

## Reference Resources ##

* Sam Methodology [sam.js.org](https://sam.js.org/)

* The [SAMCAS](https://gael-home.appspot.com/docs/samcas/api/index.html) library

* The [Rocket lib](https://gael-home.appspot.com/docs/rocket-lib/api/index.html) library

* The [Rocket App](https://gael-home.appspot.com/docs/rocket/api/index.html) a simple SAMCAS example

* The [Missile App](https://gael-home.appspot.com/docs/missile/api/index.html) a more complex SAMCAS example

* The [Rocket App Working Web Demonstration](https://gael-home.appspot.com/web/rocket/web/index.html)

* The [Missile App Working Web Demonstration](https://gael-home.appspot.com/web/missile/web/index.html)

## Source repository at GitHub ##

* [samcas-lib-dart](https://github.com/srp7474/samcas-lib-dart) SAMCAS library

* [rocket-lib-dart](https://github.com/srp7474/rocket-lib-dart) Rocket component

* [rocket-app-dart](https://github.com/srp7474/rocket-app-dart) Rocket app, needs SAMCAS library, Rocket component

* [missile-app-dart](https://github.com/srp7474/missile-app-dart) Missile App, needs SAMCAS library, Rocket component
