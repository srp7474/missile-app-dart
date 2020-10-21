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

/// These classes are used to assemble the Missile Site structure.
///
/// The structure is a hierarchy in that it contains several nested [SamModel] complexes. They
/// are organized as follows.
/// * [MissileSite] - the outer structure
/// * [Bank] - Zero or more banks for each [Missile] type that can be configured. They report (signal) to [MissileSite] as their status changes.
/// * Within each bank 1 or more [Missile] models that is independent of each other but that report (signal) to the [Bank] as to its status.
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
library site;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:async/async.dart';
import 'package:rocket_widget/rocket_widget.dart';
import 'package:samcas/samcas.dart';
import 'package:samcas/samwig.dart';
import 'missile-main.dart';
import 'dart:math';


/// Extend [Rocket] class to treat as a [Missile].
///
/// We still use [RocketFactory] as the factory and pass [Missile]
/// to that factory.
class Missile extends Rocket {
  Missile(String name): super(name:name);
}

/// The [StatefulWidget] that is the app display page once built.
///
/// This replaces the top level of the app when activated and hence starts with
/// [PlatformScaffold].
class MissileSitePage extends StatefulWidget {
  /// the app title
  final String title;
  /// the configuration data input from the user in [Config].
  final Config cfg;

  /// Constructor for [MissileSitePage].
  ///
  /// During development we log out the results to confirm values collected and to
  /// ascertain timing and sequencing of events.
  MissileSitePage({Key key, this.title,this.cfg}) : super(key: key) {
    assert(log("---- Building Site $cfg ${cfg.getHot('siteName')}"));
    assert(log("Scud ${cfg.hasHot('bnkScud')} ${cfg.getHot('bnkScud')} ${cfg.getHot('depScud')}"));
    assert(log("Patriot ${cfg.hasHot('bnkPatriot')} ${cfg.getHot('bnkPatriot')} ${cfg.getHot('depPatriot')}"));
    assert(log("Cruise ${cfg.hasHot('bnkCruise')} ${cfg.getHot('bnkCruise')} ${cfg.getHot('depCruise')}"));
  }

  /// Create State part of [StatefulWidget].
  @override
  MissileSitePageState createState () {
    log("building State Widget $cfg");
    return MissileSitePageState(cfg);
  }
}

/// State part of [StateWidget] [MissileSitePage].
class MissileSitePageState extends State<MissileSitePage> {
  MissileSite _site;
  /// The [MissileSitePageState] constructor builds [MissileSite].
  ///
  /// The [MissileSite] is configured according to the [Config] values populated
  /// during stage 1 of the app startup where we collect configuration values
  MissileSitePageState(Config cfg) {
    assert(log("Building.site $cfg"));
   _site = buildSamModel(MissileSiteFactory(MS.values,cfg),MissileSite());
    assert(log("Built.site $_site"));
  }

  /// Build the app widget tree for stage 2, the "/site" navigation path.
  ///
  /// This replaces the entire app widget tree so it starts at
  /// [PlatformScaffold].
  ///
  /// The [samInject] method is used to inject the [SamModel] [_site] into the
  /// widget tree.
  @override
  Widget build(BuildContext context) {
    //WidgetsBinding.instance.addPostFrameCallback((_) => {_site.logger.addLogLine("Site has been prepared")});
    log("build PlatformScaffold ${context.runtimeType}");
    return PlatformScaffold(
        appBar: PlatformAppBar(
           title: Text(widget.title,),
              cupertino: (_, __) =>  CupertinoNavigationBarData(transitionBetweenRoutes: false,),
        ),
        body: Center( child: samInject(_site), )
     );
  }
}

/// Return the [MissileSite] header data for a particulat [Missile] type.
///
/// The values [numBanks], [width] and [hdrHgt] are used to calculated the dimensions of this
/// section of the header. The [color] is based on the [Missile] type as seen in [MissileSiteFactory].
Widget getHeader(String name,int numBanks,int depth,double width,Color color,double hdrHgt) {
  return Container(
    child: ConstrainedBox(
        constraints: BoxConstraints.expand(height: hdrHgt, width: (width * numBanks) + (2.0 * (numBanks - 1))),
        child: Center(child:Text("${name}s: $depth",style:TextStyle(fontWeight:FontWeight.bold)))
    ),
    decoration: BoxDecoration(color: color,border:Border.all()),
  );
}

/// The [Enum](/docs/samcas/api/index.html#samcas-sammodel-companion-enum) used for [MissileSite].
enum MS {
  // ------------- states -------------
                 /// state: site is operational
  ssOperational,
                 /// state: site has only one bank left with missiles
  ssDistressed,
                 /// state: site has no banks left with missiles
  ssDefunct,
  // ------------- actions -------------
                 /// action: used in [MS.ssDistressed] to color blink the status message
  saFlash,
}

/// Constructor for [MissileSiteFactory]
///
/// We use [Config] to configure the site according to the user input data.
class MissileSiteFactory extends SamFactory {
  /// Constructor for [MissileSiteFactory]
  ///
  /// We use this ti assign color codes for each [Missile] type.
  // ignore: non_constant_identifier_names
  MissileSiteFactory(List MS,this.cfg):super(MS){
    _colMap['Patriot'] = Color.fromRGBO(243, 177, 214, 1);
    _colMap['Scud'] = Color.fromRGBO(164, 149, 251, 1);
    _colMap['Cruise'] = Color.fromRGBO(0, 217, 217, 1);
  }
  final Map _colMap = Map();
  /// Data collected from user (with suitable defaulted values).
  Config cfg;

  /// customize the Trifecta.
  @override
  formatTrifecta(SamAction sa,SamState ss,SamView sv) {
    // ---------------- action mapping ----------------
    sa.addAction(MS.saFlash,           saFlash);
    // nap processing
    sa.addAction(MS.ssDistressed,      napDistressed);
    // ---------------- signal mapping ----------------
    sa.acceptSignals(BK.values);                        // allow signals from [BK]
    sa.addAction(BK.sgBankReplen,      handleHealthCheck);
    sa.addAction(BK.sgBankDepleted,    handleHealthCheck);
    sa.addAction(BK.sgLogReq,          handleLogReq);
    // ---------------- state mapping ----------------
    ss.addState(MS.ssOperational)      .next(MS.ssDistressed);
    ss.addState(MS.ssDistressed)       .next([MS.ssDefunct,MS.ssOperational]).nap();
    ss.addState(MS.ssDefunct); // terminal state
    // ---------------- view mapping ----------------
    sv.addView("defRender",            defRender);      // use default render except for state ssDefunct
    sv.addView(MS.ssDefunct,           ssDefunct);

  }

  /// Determine health of [MissileSite] based on signals from [Bank].
  ///
  /// The [Bank] signals a change of state to its parent the [MissileSite].
  ///
  /// We use this to scan the children and ascertain the health of the site.  If only one
  /// [Bank] remains with unspent [Missile]s the [BK.ssDepleted] state is entered. If
  /// no [Banks]s have unspent [Missiles] the [MissileSite] enters the [BK.ssDefunct] state
  /// which is a terminal condition from which there is no escaspe.
  ///
  /// Since a [Bank] can be replenished the [MissileSite] can leave the [Bk.ssDistressed] state
  /// when this occurs.  The logic here handles that case to.
  void handleHealthCheck (SamModel sm, SamReq req) {
    assert(log("$sm received ${req.signal} signalled from ${req.stepParms['src']}"));
    int goodBanks = 0;
    for(Bank bank in sm.kids) {
      if (!bank.isState(BK.ssDepleted)) goodBanks += 1;
    }
    if (goodBanks == 0) {
      sm.flipState(MS.ssDefunct);
      assert(log("$sm now defunct"));
    } else if (goodBanks == 1) {
      sm.flipState(MS.ssDistressed);
      assert(log("$sm now distressed"));
    } else {
      sm.flipState(MS.ssOperational);
    }
  }

  /// This is called when the timer expires.
  ///
  /// If the [MissileSite] is still in a distressed state we restart the timer.
  ///
  /// We then create a proposal for a [MS.saFlash] which will end up with
  /// [saFlash] being invoked inside the [SamModel.present] execution scope.
  ///
  /// Code is simplified here (and other places) because Dart closures allow us
  /// to pass object instances directly ([sm]) , not a symbolic reference to them.
  void incrementCtr(MissileSite sm) {
    if (sm.samState == "${MS.ssDistressed}") sm._timer.reset();
    sm.presentNow(MS.saFlash);
    //assert(log("_incrementCtr ${sm.getHot('distressedCtr')}"));
  }

  /// [MS.saFlash] action handler.
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// We use this to increment `distressedCtr` which the [getSiteHeader] render logic
  /// has a computed dependency on and therefore this widget only will be re-rendered.
  ///
  /// We use the `req.render = true` statement as by default actions do not request a render operation.
  void saFlash(covariant MissileSite sm, SamReq req) {
    sm.setHot("distressedCtr",(sm.getHot("distressedCtr") as int) + 1);
    req.render = true;
    //assert(log("_saFlash action taken"));
  }

  /// *nap* handler for entering [MS.ssDistressed] state.
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// Note that *nap* function are not called if we flip the state into itself.
  ///
  /// If we do not have a timer instance we create it (and it will begin counting).
  ///
  /// If we have a timer (site has previously been in [MS.ssDuistressde] state, restart timer.
  void napDistressed(covariant MissileSite sm, SamReq req) {
    //assert(log("Enter distressed mode"));
    if (sm._timer == null) {
      sm._timer = RestartableTimer(sm._timerDuration,(){incrementCtr(sm);});
    } else {
      sm._timer.reset();
    }
  }

  /// Write log data to the [Logger] widget.
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// We are able to pass custom data in the request using the
  /// [SamReq.stepParms] map.
  ///
  /// In this case we color code the log messages according to the
  /// source of the log data.
  void handleLogReq(covariant MissileSite sm, SamReq req) {
    String msg = req.stepParms['msg'];
    assert(log("handleLogReq $sm $req msg=$msg"));
    Bank src = req.stepParms['src'];
    Text text = Text(msg,style:TextStyle(color:_colMap[src._missType]));
    sm.logger.addLogLine(text);
  }

  /// Default widget tree for missile site
  Widget defRender(SamModel sm) {
    return Column(
      children:[SingleChildScrollView(
          scrollDirection:Axis.horizontal,
          child: Column(children:getSite(sm,cfg,this))
      )
      ],
    );
  }

  /// [MS.ssDefunct] state widget tree for missile site
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  Widget ssDefunct(covariant MissileSite site) {
    String siteName = site.cfg.getHot('siteName') ?? "no-name";
    return Column(
      children:[
          Spacer(),
          Center(child: //Text("defunct")))]
               Container(
                 margin:EdgeInsets.symmetric(horizontal: 10.0),
                 decoration:BoxDecoration(
                   color:Colors.yellow,
                   border: Border.all(
                     width: 3,
                     color: Colors.black,
                   ),
                   borderRadius: BorderRadius.all(
                     const Radius.circular(8),
                   ),
                 ),
                 alignment:Alignment.center,
                 height:200,
                 child: RichText(text:TextSpan(text:"Site ",style:TextStyle(fontSize:22.0,color:Colors.red),
                      children:[TextSpan(text:"$siteName",style:TextStyle(fontWeight:FontWeight.bold)),TextSpan(text:" has been mothballed")]
                     )
                   ),
               ),
               ),
          Spacer(),
      ],
    );
  }
}

/// [MissileSite] [SamModel] injected into widget tree.
///
/// Several constant vales are hard coded as they represent the
/// pixel count for various components of the [MissileSite] widget tree,
///
/// The [Bank]s are not seen here because they are children accessed via the
/// [SamModel.kids] getter property.
class MissileSite extends SamModel {
  /// Un-embellished constructor.
  MissileSite();
                                    /// [Config] data collected from user
  Config cfg;
                                    /// height if banner
  static const bannerHgt  = 30.0;
  /// height if header section
  static const hdrHgt     = 30.0;
                                    /// height if silo header section
  static const siloHdrHgt = 115.0;
                                    /// height if frame height overhead
  static const frameHgt   = 88.0;
                                    /// Logger object for logging
  Logger logger;
                                    /// number missiles we show by default
  static double bankMissileDepth = 3;
                                    /// computed silo height
  static double bankSiloHgt;
  Duration _timerDuration = new Duration(seconds: 1);
  RestartableTimer _timer;

  /// Customize model before activation.
  ///
  ///
  /// We have to set the initial value of `distressedCtr`
  @override
  void makeModel(MissileSiteFactory sf,SamAction sa, SamState ss, SamView sv) {
    this.aaaName = 'site';
    cfg = sf.cfg;
    setHot("distressedCtr",0);
    //assert(logLines.add(Text("logger lines")));
  }
}

/// Return [MissileSite] widget tree.
///
/// At this point we have the [Config] data collected from the user and
/// know the screen dimensions.
///
/// These values are used to compute the size of the [MissileSite] and
/// return a widget accordingly.
List<Widget> getSite(MissileSite site,Config cfg,MissileSiteFactory sf) {
  BankFactory bankMold   = BankFactory(BK.values);
  double wid = Rocket.boxWid + 4; // 184.0 * 3;
  double hgt = Rocket.boxHgt + 4; // 184.0 * 3;
  //List<Widget> logLines =  [Text("logger line 1"),Text("logger line 2")];
  List<Widget> hdrList  = [];
  List<Widget> banks    = [];

  for (var name in "Patriot/Scud/Cruise".split("/")) {
    int numBanks = int.parse(cfg.getHot('bnk$name'));
    int depth   = int.parse(cfg.getHot('dep$name'));
    if (numBanks > 0) {
      hdrList.add(getHeader(name,numBanks,depth,wid,sf._colMap[name],MissileSite.hdrHgt));
      for (var i = 0; i < numBanks; i++) {
        banks.add(samInject(getBank(site,bankMold,cfg,name,i+1,wid,hgt,depth,sf._colMap[name])));
      }
    }
  }

  List<Widget> list = [];
  list.add(getSiteHeader(site,wid*(max(3,banks.length))));
  list.add(Row(children: hdrList));
  Row body = Row(children:banks);
  list.add(body);
  MissileSite.bankSiloHgt = MissileSite.siloHdrHgt + (hgt * MissileSite.bankMissileDepth);
  double logHgt = cfg.mediaHgt - MissileSite.hdrHgt - MissileSite.bankSiloHgt - MissileSite.frameHgt - MissileSite.bannerHgt;
  if (logHgt < 0) {
    MissileSite.bankMissileDepth = 2;
    MissileSite.bankSiloHgt = MissileSite.siloHdrHgt + (hgt * MissileSite.bankMissileDepth);
    logHgt = cfg.mediaHgt - MissileSite.hdrHgt - MissileSite.bankSiloHgt - MissileSite.frameHgt - MissileSite.bannerHgt;
  }
  if (!cfg.bIsMaterial) logHgt -= 20; //adjustment for IOS
  site.logger = Logger(site,'logger',(wid * max(3,banks.length)) + (2 * (banks.length - 2)),logHgt,color:Color.fromRGBO(250,249,253,1));
  assert(log("Calc logHgt $logHgt ${cfg.mediaHgt} material=${cfg.bIsMaterial}"));
  list.add(Row(children:[site.logger]));
  return list;
}

/// Return the top header for the site.
///
/// It changes when the state changes and does special
/// processing when the [MS.ssDistressed] state is entered.
Widget getSiteHeader(MissileSite site,double wid) {
  String siteName = site.cfg.getHot('siteName') ?? "no-name";
  return
  Container(
      color:Color.fromRGBO(242, 240, 249, 1),
      height:MissileSite.bannerHgt,
      width:wid+4,
      child:
        Row(children:[
          //Spacer(),
          Text("Missile Site: "),
          Text("$siteName",style:TextStyle(fontWeight:FontWeight.bold)),
          Text("          Site Status: "),
          site.watch((SamBuild sb) {
            //log("building header ${site.getHot('distressedCtr')}");
            if (site.isState(MS.ssDistressed)) {
              Color color = ((site.getHot("distressedCtr") as int) % 2 == 0)
                  ? Colors.red
                  : Colors.orange;
              return Text("${site.samState}".substring(5),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color));
            } else {
              return Text("${site.samState}".substring(5),
                  style: TextStyle(fontWeight: FontWeight.bold));
            }
          })
          //Spacer(),
          ]));
}

/// Return a [Bank] [SamModel]
///
/// The [Bank] is configured according to parameters passed.
Bank getBank(MissileSite site,SamFactory bankMold,Config cfg,String name,int ix,double wid,double hgt,int depth,Color color) {
  Bank bank = buildSamModel(bankMold,Bank(color,name,ix,wid,hgt,depth),parent:site);
  return bank;
}

/// The [Enum](/docs/samcas/api/index.html#samcas-sammodel-companion-enum) used for [Bank].
enum BK {
  // ---------------- actions ----------------
  saIncoming,
  saReqReplen,
  // ---------------- states -----------------
  ssActive,
  ssEngaged,
  ssDepleted,
  // ------------- signals we emit -----------
  sgBankReplen,
  sgBankDepleted,
  sgLogReq,
}

/// Delay Enums for Picker
enum Delay {
  delay10,
  delay20,
  delay30,
}

// Factory to build [Bank] model
class BankFactory extends SamFactory {
  /// Constructor that specifies [Enum](/docs/samcas/api/index.html#samcas-sammodel-companion-enum)
  BankFactory(List enums):super(enums);

  /// format the Trifecta.
  @override
  formatTrifecta(SamAction sa, SamState ss, SamView sv) {
    // ---------------- action mapping ----------------
    sa.addAction(BK.saIncoming,    saIncoming);
    sa.addAction(BK.saReqReplen,   (SamModel sm, SamReq req) {sm.flipState(BK.ssActive);}); // simple cases can be coded here
    // ---------------- signal mapping ----------------
    sa.acceptSignals(RK.values);                   // allow signals from RK
    sa.addAction(RK.sgLaunching,   (SamModel sm, SamReq req) {handleRocketSignal(sm,req);});
    sa.addAction(RK.sgAborting,    (SamModel sm, SamReq req) {handleRocketSignal(sm,req);});
    sa.addAction(RK.sgPausing,     (SamModel sm, SamReq req) {handleRocketSignal(sm,req);});
    sa.addAction(RK.sgCounting,    (SamModel sm, SamReq req) {handleRocketSignal(sm,req);});

    // ---------------- state mapping ----------------
    ss.addState(BK.ssActive)       .next(BK.ssDepleted).signal(BK.sgBankReplen);
    ss.addState(BK.ssEngaged);
    ss.addState(BK.ssDepleted)     .next(BK.ssActive).signal(BK.sgBankDepleted);
    // ---------------- view mapping ----------------
    sv.addView("defRender",        defRender);     // default unless [BK.ssDepleted]
    sv.addView(BK.ssDepleted,      ssDepletedRender);
  }

  /// action handler for [BK.saIncoming] button press
  ///
  /// We find dormant [Missile]s by looking at the children
  /// and start them.  The `stepParms` map is used to pass the
  /// delay factor which increases every iteration.
  void saIncoming(SamModel sm,SamReq req) {
    assert(log("clickIncoming $sm"));
    int incr = 0;
    int delay = sm.getHot("delay");
    for(Missile m in sm.kids) {
      assert(log("start $m"));
      if (m.isState(RK.ssReady)) {
        m.presentNow(RK.saStartCtr,stepParms:{"delay":delay + incr});
        incr += delay;
      }
    }
  }

  /// we have received a signal from the child [Missile].
  ///
  /// We use this to generate a log message and send to the parent.
  ///
  /// We also use this to inspect the state of the [Bank] by looking
  /// at the remaining child [Missile]s. When the number of unspent missiles is
  /// 0 we flip ourself into a [BK.ssDepleted] state.
  void handleRocketSignal(SamModel sm,SamReq req) {
    assert(log("rocketSignal ${req.signal}"));
    var signal = req.signal as RK;
    Rocket r = req.stepParms['src'];
    assert(log("signal $signal $sm processed src=${r.rocketName}"));
    String msg = "${r.rocketName} ";
    switch(signal) {
      case RK.sgLaunching: msg += " launched";                   break;
      case RK.sgAborting:  msg += " launch aborted";             break;
      case RK.sgPausing:   msg += " launch paused";              break;
      //case RK.sgCounting:  msg += " countdown started/resumed";  break;
      default:msg += "signal $signal not defined";               break;
    }
    sm.parent.presentNow(BK.sgLogReq,stepParms:{'src':sm,'msg':msg});
    // Check to see if need to signal depleted
    int numGood = 0;
    for(Missile m in sm.kids) if (m.isState([RK.ssReady,RK.ssCounting,RK.ssWaiting,RK.ssPaused])) numGood += 1;
    if (numGood == 0) sm.flipState(BK.ssDepleted);

  }

  // Display the 'auto' section of the [Bank] header.
  String autoStr(SamModel sm,Object x) {
    bool bAuto = sm.getHot("auto");
    //log("getAutoStr ${sm.getHot('delay')}  ${sm.getHot('auto')} $bAuto");
    if (!bAuto) {
      return "Enable Auto";
    } else {
      return "Auto (Delay ${sm.getHot('delay')})";
    }
  }

  /// Render the case we are depleted
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  Widget ssDepletedRender(covariant Bank sm) {
    return Container(
        //height:MissileSite.siloHdrHgt,
        decoration:BoxDecoration(
          color: sm._color,
          border:Border(left:BorderSide(),right:BorderSide()),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(height:MissileSite.bankSiloHgt,width:sm._wid),
          child: Column(
              children: [
                Center(child:Text("Bank ${sm._bankName}")),
                Spacer(),
                Center(child:Text("DEPLETED",style:TextStyle(fontSize:20.0,fontWeight:FontWeight.bold))),
                Spacer(),
                fancyButton(sm,action:BK.saReqReplen,label:"Replenish",width:120),
                Spacer(),
              ]),
        )
    );
  }

  /// Render all other state cases
  Widget defRender(covariant Bank sm) {
    List<Widget> listv = [];
    for (var i = 0; i < sm._depth; i++) {
      listv.add(Container(
          decoration:BoxDecoration(
            color: sm._color,
          ),
          child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: sm._wid, width: sm._hgt),
              child:samInject(buildSamModel(RocketFactory(RK.values),Missile("${sm._missType}-${sm._ix}-${i+1}"),parent:sm))
          )
      ));
    }
    List<Widget> list = [];
    list.add(Container(
        decoration:BoxDecoration(
          color: sm._color,
          border:Border(left:BorderSide(),right:BorderSide()),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(height:MissileSite.siloHdrHgt,width:sm._wid),
          child:
          sm.watch((SamBuild sb)=>
            Column(
              children: [
                Center(child:Text("Bank ${sm._bankName}")),
                //genCheckbox(sm,'auto',(SamModel sb,Object x) => autoStr(sm,x),changeExec:changeAutoMode),
                genSwitch(sm,'auto',(SamModel sb,Object x) => autoStr(sm,x),changeExec:changeAutoMode),
                Visibility(
                  visible:sm.getHot("auto"),
                  child:Row(children:[Spacer(),fancyButton(sm,action:BK.saIncoming,label:"Incoming",width:120,height:25),Spacer()])
                )
              ]),
          )
        )
      ));
    list.add(
        Container(
            decoration:BoxDecoration(
              color: sm._color,
              border:Border(left:BorderSide(),right:BorderSide()),
            ),
            child: ConstrainedBox(
                constraints: BoxConstraints.expand(height:sm._hgt * min(MissileSite.bankMissileDepth,sm._depth),width:sm._wid),
                child: ListView(children:listv)
            )
        )
    );
    return Column(children: list);
  }

  /// We have changed the `auto` mode setting.
  ///
  /// We tailor the [Bank] header accordingly.
  void changeAutoMode(covariant Bank bank,String sym,bool value) async {
    assert(log("changeAutoMode $sym $value"));
    if (value) {
      final int delay = await getChoiceValue(bank.getBuildContext(),title:"Select delay value",labels:["Delay 10","Delay 15","Delay 20"],values:[10,15,20]) ?? 10;
      assert(log("have delay $delay"));
      bank.presentNow(SE.sa_change,stepParms:{'actMap':{'sym':'delay','value':delay}});
    }
  }

}

// [Bank] [SamModel] built by [BankFactory]
class Bank extends SamModel {
  /// Construct preserves build parameters
  Bank(this._color,this._missType,this._ix,this._wid,this._hgt,this._depth) {
    this._bankName = "$_missType-$_ix";
  }
  String _missType;
  int _ix;
  int _depth;
  String _bankName;
  Color _color;
  double _hgt;
  double _wid;

  /// Populates the [Bank] model.
  ///
  /// Sets initial values for `delay` and `auto`.
  makeModel(BankFactory bm,SamAction sa, SamState ss, SamView sv) {
    this.aaaName = _bankName;
    this.setHot("delay",10);
    this.setHot("auto",false);
    assert(log("buildBank.defRender $_missType $_bankName"));
  }
}
