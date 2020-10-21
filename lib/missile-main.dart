/* MIT License
Copyright (c) <2020> <Steve Pritchard of Rexcel Systems Inc.>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// The missile portion of the app provides app navigation and initial configuration.
///
/// The app runs in 2 parts. The first handles the configuration. The second takes the
/// parameters supplied by the configuration process and builds a [site](docs/missile/api/site/site-library.html) accordingly.
///
/// Typically many of these classes and methods would be *private*.  They are kept *public* here so that the code can
/// be documented.
///
/// Names are very important in Flutter applications and can be used to find
/// dependent parts of application code using the tools provided with *Android Studio*
/// (and presumably with *Visual Studio*).
///
/// During development we use [log] statements to record useful data and to
/// ascertain timing and sequencing of events. We use the [log] statement wrapped in an
/// *assert* statement so that the log statement and literal values disappear in production mode.
///
/// The dart literal interpolation is a major help in doing the logging.

library missile;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:samcas/samcas.dart';
import 'package:samcas/samwig.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as dev;
import 'site.dart';

/// The app start entry point.
///
/// It provides a framework that is host platform aware and also formats the
/// initial screen according to the screen size constraints using the [MeasuredSize] class.
///
/// Note that we use the first builder function to obtain the [MediaQueryData]
/// so that the [ConfigFactory] has this information. So that the [MediaQuery] has context we use
/// we use the [Builder] to delay this cycle.
void main() {
  /// Used to post *Debug* flag
  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  /// App title with *Debug* flag
  const title = 'SAMCAS Missile Site Demo V 1.0 ${isProduction?"":"(Debug)"}';
  /// The Widget tree representing the first stage of the app.
  MissileHomePage mhp;

  /// The runApp provided by Flutter used to build initial widget tree.
  ///
  /// The use of [PlatformProvider] allows for switching based on the
  /// host platform type.
  ///
  /// The [MissileHomePage] provides the bulk of the widget tree.
  ///
  /// **NOTE:** A very tricky issue was encountered building this app. It would appear
  /// that the *Flutter Hot Restart* facility populates classes that we previously populated
  /// with half-baked instances. In this case the Config instance was populated with a model
  /// that never went through the proper population methods.  I have posted a question on
  /// StackOverflow to try and understand more.
  ///
  runApp(PlatformProvider(
    //initialPlatform:  TargetPlatform.iOS, // To jam the platform for testing.
    builder:(BuildContext contextA){
      log("building PlatformApp");
      return PlatformApp(
       title: 'Missile App Flutter/SAMCAS Demo',
        material:(_,__) => MaterialAppData(theme: materialThemeData),
        cupertino:(_,__) => CupertinoAppData(theme: cupertinoTheme),
        home: Builder( // we delay 1 cycle so can do MediaQuery
          builder:(BuildContext contextB){
            MediaQueryData mqd = MediaQuery.of(contextB);
            mhp = MissileHomePage(mqd,isMaterial(contextB),title: title);
            return mhp;
          }
        ),
        onGenerateRoute: (settings) {
         log("onGenerateRoute ${settings.name}");
         if (settings.name == "/site") {
           Config appCfg = settings.arguments;
           log("onGenerateRoute $appCfg");
           if (isMaterial(contextA)) {
             return MaterialPageRoute(builder: (context) => buildSitePath(contextA, appCfg, title));
           } else {
             return CupertinoPageRoute(builder: (context) => buildSitePath(contextA, appCfg, title));
           }
         }
         return null;
        },
      );}
    ),
  );
}

/// Build the [MissileSitePage] to be used in the "/site" navigation path.
///
/// This can only be built once the configuration parameters are chosen by the user. The are
/// supplied by the [mhp] parameter which points to the [Config] which is a [SamModel] containing
/// the user supplied values.
///
/// It returns a full widget stack starting at [PlatformScaffold]. Refer to
/// [site](/docs/missile/api/site/site_main-library.html) for more details.
Widget buildSitePath(BuildContext context,Config cfg,String title) {
  assert(log("buildSitePath cfg $cfg title $title ${cfg.dumpSamHot()}"));
  return MissileSitePage(cfg:cfg,title:title);
}

/// Supplied Theme data for *Material* hosted platforms.
///
/// Changing these values will change the overall look of the app
/// when the app is running on a *Material* device.
final materialThemeData = ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    accentColor: Colors.blue,
    appBarTheme: AppBarTheme(color: Colors.blue.shade600),
    primaryColor: Colors.blue,
    secondaryHeaderColor: Colors.blue,
    canvasColor: Colors.blue,
    backgroundColor: Colors.red,
    textTheme: TextTheme().copyWith(bodyText1: TextTheme().bodyText2)
);

/// Supplied Theme data for *Cupertino* hosted platforms.
///
/// Changing these values will change the overall look of the app
/// when the app is running on a *Cupertino* device.
final cupertinoTheme = CupertinoThemeData(
    primaryColor: Colors.blue,
    barBackgroundColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white
);


/// Configuration Action, State, [Enum](/docs/samcas/api/index.html#samcas-sammodel-companion-enum) for [Config] model.
enum CF {
  // actions
             /// action: Build the missile site
  saBuild,
  // States
             /// state: Configurator is ready
  ssReady,
             /// state: Configuration is completed
  ssDone,
}

/// The factory used to build the [Config] model.
class ConfigFactory extends SamFactory {
  ConfigFactory(List enums):super(enums);


  /// This formats the Trifecta.
  ///
  /// Note that [CF.ssDone] normally is a terminal state (no *allow* or *nap* modifiers)
  /// except that the [Config.makeModel] method adds a *nap* modifier used to add a dynamic
  /// handler for when the [Config] is completed.
  ///
  /// The [CF.saBuild] is the action event of the **Build** button which will flip the
  /// model into the [CF.ssDone] state.
  @override
  formatTrifecta(SamAction sa, SamState ss, SamView sv) {
    // ---------------- action mapping ----------------
    sa.addAction(CF.saBuild,    (SamModel sm, SamReq req) {sm.flipState(CF.ssDone);});
    // ---------------- state mapping ----------------
    ss.addState(CF.ssReady)     .next(CF.ssDone);
    ss.addState(CF.ssDone);
    // ---------------- view mapping ----------------
    sv.addView("defRender", defRender);
  }

  /// The default [Config] rendering.
  ///
  /// Note that the [onFocus] event is used  for the [inputBox] so that the
  /// RichText paragraph can be hidden. See [page1];
  Widget defRender(SamModel sm) {
    assert(log("rendering build site widgets"));
    return SizedBox(
      width:(sm as Config).prefWid,
      child: Center(
        child: Form(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                style: BorderStyle.solid,
                color: Colors.grey,
              ),
              color: Color.fromRGBO(242, 240, 249, 1),
            ),
            child: Column(
              children: [
                row(text("Build Missile Site:",fontSize:24,fontWeight:FontWeight.bold)),
                row(inputBox(sm,sym:'siteName',label:'Optional site name',onFocus:(sm as Config).onFocus)),  //hint: 'Enter optional site name',
                row(Text("")),
                getMissileRow(sm, "Patriot"),
                getMissileRow(sm, "Scud"),
                getMissileRow(sm, "Cruise"),
                row(fancyButton(sm,action:CF.saBuild,label:"Build Site")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Given the missile type [what] return a row with configuration options.
  ///
  /// This makes use of the [samwig](/docs/samcas/api/samwig/samwig-library.html) components
  /// that will adapt according to the host platform and update the [Config] model with
  /// the results of any changes.
  Row getMissileRow(SamModel sm, String what) {
    String symBanks = "bnk$what";
    String symDepth = "dep$what";
    List<Widget> list = [];
    list.add(
      ConstrainedBox(
        constraints: BoxConstraints.tight(Size(120, 60)),
        child: Text(
          "$what Missiles:",
          style:
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 2.8),
          textAlign: TextAlign.right,
        ),
      ),
    );
    list.add(genPlatformPicker(sm, symBanks, "0/1/2/3", value:"1",label:"   Banks: "));
    list.add(genPlatformPicker(sm, symDepth, "1/2/3/4/5",value:"3",label:"      Depth: "));
    return Row(children: list);
  }

}

/// Constructor for the [Config] model.
///
/// This is used to allow the user to customize the site before it is
/// built. The number of missiles in each bank and the number of banks can be
/// varied for the 3 types of missiles this application allows for.
///
///
class Config extends SamModel {
  /// Construct the extended model that wil be further populated at [ConfigFactory.makeModel].
  Config(this.mqd,this.bIsMaterial):super();
                                /// Used to set the other values. See [ConfigFactory.makeModel].
  final MediaQueryData mqd;
  /// The screen height of device we are running on
  double mediaHgt;
  /// The screen width of device we are running on
  double mediaWid;
  /// The preferred width. Set to a maximum of 600 for Web platform.
  double prefWid;
  /// The height we can use after headers subtracted.
  double biasHgt;
  /// The height we can use after the top form is subtracted.
  double availHgt;
  /// True if  running *Material* mode vs *Cupertino* mode.
  final bool bIsMaterial;

  /// track what copy we are looking at during development
  int curVer;
  static int verCtr = 0;
  @override
  String toString() {
    return "${super.toString()} ver=$curVer";
  }

  /// Used to control the visibility of the RichText paragraph when the
  /// keyboard is present.
  bool   inputHasFocus = false;
  /// Function that is executed.
  FocusFunc onFocus;

  static Config findConfig(BuildContext context) {
    SamInject si = context.findAncestorWidgetOfExactType<SamInject>();
    log("Found si $si");
    log("Found appCfg ${si.sm}");
    return si.sm;
  }


  /// Populate [Config] variables.
  ///
  /// This is executed before the [SamModel] is activated.
  /// We use it to mutate values before we are in the constraint of only
  /// doing so within the [SamModel.present] execution scope.
  ///
  /// We populate the [onFocus] handler used in the [defRender] view.
  ///
  /// We also add a *nap* handler [siteDefined] to illustrate how to transition to a completely new
  /// navigation page.
  ///
  @override
  makeModel(SamFactory sf,SamAction sa, SamState ss, SamView sv) {
    curVer = ++verCtr;
    mediaHgt = mqd.size.height;
    mediaWid = mqd.size.width - 20;
    biasHgt = mqd.padding.top + kToolbarHeight;
    assert(log("media ${mqd.size}"));
    //var plat = Platform();
    assert(log("platform $kIsWeb"));
    if (kIsWeb && mediaWid > 600) prefWid = 600;
    availHgt = mqd.size.height - biasHgt;

    dev.log("makeModel $this ver=$verCtr ${dumpSamHot()}");
    DefState ds = ss.ssMap["${CF.ssDone}"];
    ds.fncNap = siteDefined;
    onFocus = (bool hasFocus){log("model hasFocus $hasFocus"); this.inputHasFocus = hasFocus;};
  }

  /// Transition to build the missile site.
  ///
  /// The *Navigator* method used where we have defined what happens when the "/site" route
  /// is activated.  Here we say we want to enter this path.  We also use the BuildContext of this model
  /// so that *Navigator* has a context.
  void siteDefined(SamModel sm, SamReq req) {
    assert(log("---- SiteDefined $sm $req ${sm.getHot('siteName')} ${sm.getBuildContext()} ${sm.getBuildContext().widget.key}"));
    assert(log("Scud ${sm.getHot('bnkScud')} ${sm.getHot('depScud')}"));
    assert(log("Patriot ${sm.getHot('bnkPatriot')} ${sm.getHot('depPatriot')}"));
    assert(log("Cruise ${sm.getHot('bnkCruise')} ${sm.getHot('depCruise')}"));
    Navigator.popAndPushNamed(sm.getBuildContext(),"/site",arguments:sm as Config);
  }
}

/// Stateful widget representing Form input dialog that populates [Config].
///
/// This is the form input that populates the [Config] model which
/// is passed to the site builder.
///
/// The [Config] model is built in the constructor of this page.
// ignore: must_be_immutable
class MissileHomePage extends StatefulWidget {

  /// Construct [MissileHomePage] and build [Config] which is used in the
  /// widget tree.
  MissileHomePage(this._mqd,this._bIsMaterial,{Key key, this.title}) : super(key: key) {
    if (_cfg == null) _cfg = buildSamModel(ConfigFactory(CF.values),Config(_mqd,_bIsMaterial));
  }
  final MediaQueryData _mqd;
  final bool _bIsMaterial;
  /// App page title
  final String title;
  Config _cfg;

  /// Create State part of StateFulWidget
  @override
  MissileHomePageState createState () {
    return  MissileHomePageState(_cfg);
  }
}

/// Stages and results of the measuring process.
///
/// We cycle through these states as we determine how to layout the page
/// depending on the screen size.
enum Host {
                  /// initial measurement
  measuring,
                  /// normal fit
  large,
                  /// scrolled fit
  small,
                  /// could not compute
  undef,
}

/// State portion of [MissileHomePage].
///
/// The page is laid out twice as we have to do it based
/// on the screen size and the need to ascertain the dimensions of the
/// RichText widgets.
///
/// The [MeasuredSize] widget is used to do the measuring.
///
/// The [setState] method is used to force a new rendering of the widget tree.
///
class MissileHomePageState extends State<MissileHomePage>  {
  /// Construct the State instance.
  MissileHomePageState(this._cfg);
  final Config _cfg;
                                     /// controls load pge processing. See [Host].
  Host  loadStage = Host.measuring;
                                     /// We save the context as a reference point
  BuildContext saveContext;
                                     /// the computed dimensions of the RichText panel
  double botPanSize;
                                     /// The size of the [Config] form
  Size cfgSize;
                                     /// The size of the RichText based on width of platform.
  Size txtSize;


  /// method to measure the text.  This is called when [loadStage] is
  /// of [Host.measuring]. It uses the [Offstage] mode so that the user never
  /// sees the RichText until the layout is complete.
  ///
  /// The [child] is the text returned by [bottomSheet].
  ///
  /// The [callback] is called by the [MeasuredSize] widget.
  Widget measureText(BuildContext context) {
    return MeasuredSize(
        child:Offstage(child:bottomSheet(context,false)),
        callback:(Size sz){
            assert(log("callBack.txt $sz"));
            txtSize = sz;
            _cfg.prefWid = sz.width;
            if (_cfg.prefWid > 600) _cfg.prefWid = 600;
          },
        offstage:true
    );
  }

  /// Build the widget tree according to the [loadStage] setting.
  ///
  /// WidgetsBinding.instance.addPostFrameCallback is used to add a method
  /// that does the measuring. It is there that the [setState] function is
  /// called that rebuilds the widget tree.  This only happens when
  /// we are measuring so that an infinite loop does not occur.
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      assert(log("postBuild screen sz(${_cfg.mediaWid} ,${_cfg.mediaHgt}) bias ${_cfg.biasHgt} cfgSize $cfgSize txtSize $txtSize avail ${_cfg.availHgt}"));
      if ((cfgSize != null) && (txtSize != null) && (loadStage == Host.measuring)) {
        if (cfgSize.height + txtSize.height < _cfg.availHgt) {
          setState(() {loadStage = Host.large;});
        } else {
          setState(() {loadStage = Host.small;});
          botPanSize = _cfg.availHgt - cfgSize.height;
        }
        assert(log("reported $loadStage $botPanSize"));
      } else {
        if ((txtSize == null) && (loadStage == Host.measuring)) {
          setState(() {loadStage = Host.measuring;});
        }
      }
    });

    Widget page = page1(this, context);
    return page;
  }

  /// Initial widget tree for Missile App.
  ///
  /// This is where we use the [MeasuredSize] widget to measure the RichText size.
  ///
  /// We also used a Builder so that we can build depending on the [loadStage] setting.
  Widget page1(State state, BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(widget.title, /*style: toolbarTextStyle,*/),
        cupertino: (_, __) =>
            CupertinoNavigationBarData(
              transitionBetweenRoutes: false,
            ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            MeasuredSize(child:samInject(_cfg),callback:(Size sz){log("callBack $sz");cfgSize = sz;}),
            Spacer(),
            Builder(
              builder:(context) {
                log("builder.MeasuredSize at $loadStage $_cfg");
                switch(loadStage) {
                  case Host.measuring: return Column(children:[Text("Measure Marker"),measureText(context)]);
                  case Host.large: return bottomSheet(context,_cfg.inputHasFocus);
                  case Host.small: return
                      Visibility(
                         visible:!_cfg.inputHasFocus,
                         child:SizedBox(
                           height:botPanSize,
                           child: SingleChildScrollView(
                            scrollDirection:Axis.vertical,
                            child: bottomSheet(context,false)
                           ),
                         )
                      );
                  default: return Column(children:[Text("Initial $loadStage")]);
                }
              }
            )
         ],
       ),
      ),
    );
  }

  /// RichText used to give the user some information about the app.
  ///
  /// It demonstrates the use of the [Para] class to generate RichText.
  ///
  /// The [Visibility] widget is used to hide it when the input keyboard appears as otherwise
  /// it may cause a rendering overflow error.
  ///
  /// It is also generated multiple times during the load phase of this page
  /// because it has perhaps be scrolled if it exceeds the screen capacity.
  Widget bottomSheet(BuildContext context,bool hasFocus) {
    assert(log("bottomSheet ${context.runtimeType} hasFocus=$hasFocus"));
    int widBias = kIsWeb?0:10;
    return Visibility(
      visible:!hasFocus,
      child: SizedBox(
        width:_cfg.prefWid,
        child: Container(
            //color:Color.fromRGBO(242,240,249,1),${
            decoration: BoxDecoration(
              border: Border.all(
                style: BorderStyle.solid,
                color: Colors.grey,
              ),
              color: Color.fromRGBO(242, 240, 249, 1),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                constraints: new BoxConstraints(
                    maxWidth: (_cfg.prefWid != null)?_cfg.prefWid - widBias:_cfg.mediaWid - 5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Para().p("This is a demonstration implementation of ").b("SAMCAS")
                        .p(
                        " that uses the methodology proposed by Jean-Jacques Dubray found at ")
                        .a("The SAM Pattern", "https://sam.js.org/")
                        .p(" and implemented using the ").b("Dart/Flutter").p(
                        " platform.")
                        .emit(),
                    Para().p("This app uses the companion ").i("Rocket Launcher App")
                        .p(" to demonstrate the component capability of ").b("SAMCAS")
                        .p(
                        ". The Flutter rendering design is very compatible with the SAM methodology and results in a resource (memory, CPU) efficient application.")
                        .emit(),
                    Para().p("Thanks to the ").b("Dart/Flutter").p(
                        " development platform the same codebase will execute")
                        .p(
                        " in a Web browser, on a Linux/Windows/MAC desktop or on phone/tablet devices running Android or iOS.")
                        .p(" More information can be obtained at ")
                        .a("SAMCAS implementation", "https://gael-home.appspot.com/docs/samcas/api/index.html")
                        .p(
                        " while the Android and iOS implementations may be found at ")
                        .i("The Google Play Store").p(" or ").i("The Apple Store").p(
                        " respectively.")
                        .emit(),
                    //==============
                    // used to stress the RichText size for various screen size testing.
                    /*

                    Para().p("Thanks to the ").b("Dart/Flutter").p(
                        " development platform the same codebase will execute")
                        .p(
                        " in a Web browser, on a Linux/Windows/MAC desktop or on phone/tablet devices running Android or iOS.")
                        .p(" The first 3 can be obtained at.")
                        .a("SAMCAS implementations", "http://stevepritchard.ca/")
                        .p(
                        " while the Android an iOS implementations may be found at ")
                        .i("The Google Play Store").p(" or ").i("The Apple Store").p(
                        " respectively.")
                        .emit(),
                    Para().p("Thanks to the ").b("Dart/Flutter").p(
                        " development platform the same codebase will execute")
                        .p(
                        " in a Web browser, on a Linux/Windows/MAC desktop or on phone/tablet devices running Android or iOS.")
                        .p(" The first 3 can be obtained at.")
                        .a("SAMCAS implementations", "http://stevepritchard.ca/")
                        .p(
                        " while the Android an iOS implementations may be found at ")
                        .i("The Google Play Store").p(" or ").i("The Apple Store").p(
                        " respectively.")
                        .emit(),
                    Para().p("Thanks to the ").b("Dart/Flutter").p(
                        " development platform the same codebase will execute")
                        .p(
                        " in a Web browser, on a Linux/Windows/MAC desktop or on phone/tablet devices running Android or iOS.")
                        .p(" The first 3 can be obtained at.")
                        .a("SAMCAS implementations", "http://stevepritchard.ca/")
                        .p(
                        " while the Android an iOS implementations may be found at ")
                        .i("The Google Play Store").p(" or ").i("The Apple Store").p(
                        " respectively.")
                        .emit(),
                    Para().p("Thanks to the ").b("Dart/Flutter").p(
                        " development platform the same codebase will execute")
                        .p(
                        " in a Web browser, on a Linux/Windows/MAC desktop or on phone/tablet devices running Android or iOS.")
                        .p(" The first 3 can be obtained at.")
                        .a("SAMCAS implementations", "http://stevepritchard.ca/")
                        .p(
                        " while the Android an iOS implementations may be found at ")
                        .i("The Google Play Store").p(" or ").i("The Apple Store").p(
                        " respectively.")
                        .emit(),

                     */


                  ],
                ),
              ),
            ]),
            //),
            //),
          ),
      ),
    );
  }
}