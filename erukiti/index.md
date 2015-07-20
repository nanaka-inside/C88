title: ElectronとRxでイマドキなアプリ
author: erukiti_

はじめまして、erukitiと申します(Twitterではerukiti_)。みなさんはWindowsやMacで動作するデスクトップアプリケーションを書いたことがありますか？僕は大昔にWin32APIとC言語を使って書いたことがありますが、開発やデバッグはそれなりに大変なものでした。時代は進んでウェブ技術を使って簡単にデスクトップアプリケーションを書けるようになりました。今回はElectronとRxという技術を使って簡単なアプリケーションを書いてみたいと思います。

ウェブ技術でアプリを書けるElectron
----------------------------------

ElectronはGithub社がクロスプラットフォームで動くテキストエディタAtomを作るために公開されているフレームワークです。以前はAtom-Shellという名前でしたが、2015年4月23日にElectronという名前に変わりました。情報を検索するときに念頭に置いておくといいかもしれません。Electronは主にNode.jsとChromiumで構成されています。

Node.jsはウェブブラウザとは独立したJavaScriptの処理系で、手元のコマンドラインでJavaScriptを動かすことができます。最近ではウェブ開発においても、いろいろなツールを必要とする点でNode.jsの重要性が増しているため、インストールしておいて損はないでしょう。もちろんElectronアプリケーションの開発においても必須です。また、ChromiumはGoogle社の開発しているオープンソースのウェブブラウザで、Chromeの母体となるものです。

* Electronで作られたアプリはクロスプラットフォーム(Windows, Mac, Linux)で動きます。
* ウェブ技術(HTML+JavaScript)でアプリケーションを作れます。

環境整備
--------

Node.jsをインストールしていない方はまずはNode.jsをインストールしましょう。https://nodejs.org/にアクセスして真ん中に輝くINSTALLのボタンを押してみてください。それぞれのOSに応じたインストール用のファイルをダウンロードできるはずです。

さて、Node.jsを使うためにはコマンドラインが必要です。Windowsの方は何らかのコマンドライン、MacやLinuxの方はお好みのターミナルを開いてみてください。以下はMacを前提に書きますが、Windowsの人はいい感じに読み替えてみてください。

うまく`node`コマンドが実行できればパッケージマネージャの`npm`もインストールされているはずです。作業ディレクトリに移動して初期化をしましょう。`npm init -y`を実行してauthor(あなたの名前)を入力すればパッケージをインストールできるようになります。`electron-prebuilt`, `express`, `rx` の三つのパッケージを作業ディレクトリにインストールしましょう。

```
$ node -e 'console.log("hello, world");'
hello, world
$ npm init -y
author: <あなたの名前>
$ npm install electron-prebuilt express rx --save
```

ElectronでHello World.
----------------------

環境も整ったのでElectronでHello, Worldを表示するアプリケーションを書いてみたいと思います。まずは、Electronを起動するためのコードを書きます。ここではapp.jsというファイル名でコードを書きます。

```
var app = require('app');
var BrowserWindow = require('browser-window');

app.on('window-all-closed', function() {
  app.quit();
});

var mainWindow = null;

app.on('ready', function() {
  mainWindow = new BrowserWindow({width: 800, height: 600});
  mainWindow.loadUrl('file://' + __dirname + '/index.html');
  mainWindow.on('closed', function() {
    mainWindow = null;
  });
});
```

見ればなんとなくわかるかもしれません。BrowserWindowオブジェクトを生成することでElectronに内蔵されたChromiumのウィンドウが開かれ、loadUrlメソッドでapp.jsと同じディレクトリにあるindex.htmlが開かれます。このindex.htmlにはひとまず<code>Hello, World.</code>とだけ書いておきましょう。

あとは、コマンドラインで<code>./node_modules/.bin/electron app.js</code>を実行すれば、Hello, world.と書かれた白いウィンドウが開くはずです。

### TIPS

* メニューのViewからToggle Developer Toolsを開くか、Command+Option+I を押せば、Chromeと同じDeveloper Toolsを使用することができます。デバッグの便利なので是非とも使いこなしましょう。

Rx (Reactive Extensions)
------------------------

Rxは非同期処理をコレクション操作と同じように書ける、FRP(関数語リアクティブプログラミング)を実現してくれるライブラリで、元々Microsoftが.Netで開発したもので今はMicrosoftやNetflixが様々な言語に移植しているもので、その中でもRxJSはRxのJavaScript版です。例えばこのプログラムは、画面をクリックしたら、コンソールにclickedと表示するプログラムです。

```
Rx.Observable.fromEvent(document, "mouseup")
  .subscribe(function(ev) {console.log("clicked"))
```

ストリーム・メッセージ・オペレータ
----------------------------------

Rxではデータの流れる一連の流れをストリームと呼びます。上記サンプルの`Rx.Observable.fromEvent(...)`で生成されるのがストリームで、このストリームにはマウスのボタンを放した時のイベントが流れます。`Rx.Observable.just(1, 2, 3)`ならば、1と2と3が流れるストリームです。このストリームに流れるデータをメッセージと言います。

ストリームをsubscribe()すればメッセージを受信して、それに応じた処理を行うことができますが、単にマウスボタンのイベントを受信するだけでは物足りなく感じるところです。そこでオペレータと呼ばれる、メッセージを加工する処理を行ってみましょう。

```
Rx.Observable.just("hoge", "fugapiyo")
  .map(function(s) {return s.length;})
  .subscribe(function(n) {console.log(n);)
```

mapオペレータは、メッセージを加工することができます。メッセージの文字列を、長さの数字に変換しているものです。

Electron+Rx
-----------

Rxについて概略を説明したところで、Electronのコードで実際にRxを使ってみましょう。まずは先ほどは`Hello, World.`としか書かなかったindex.htmlを書き換えてみましょう。

```
<!DOCTYPE html>
<html lang="ja">
  <meta charset="utf-8">
  <title>Electron</title>
  <body style="font-family: '游ゴシック', YuGothic, 'ヒラギノ角ゴ ProN W3', 'Hiragino Kaku Gothic ProN', Avenir, 'Helvetica neue', Helvetica, メイリオ, Meiryo, 'ＭＳ Ｐゴシック', serif;">
    <div id="test"></div>
    <script src="node_modules/rx/dist/rx.all.js"></script>
    <script src="renderer.js"></script>
  </body>
</html>
```

ポイントは二つあって、htmlタグで`lang="ja"`を指定したことと、bodyタグのstyleにフォントファミリーを指定したことです。デフォルト状態では日本語をうまく処理してくれないので、langと日本語フォントを設定しないといけないのです。

さて、次にrenderer.jsを書いてみましょう。ここではRxの簡単なコードを書いてみようかと思います。さきほどRxの説明にもあったマウスクリックにまつわる処理をここでは書いてみます。

```
var clickStream = Rx.Observable.fromEvent(document, "mouseup");
var test = document.getElementById('test')
clickStream
    .buffer(clickStream.throttle(250))
    .map(function(x) {return x.length})
    .filter(function(n) {return n >= 2})
    .subscribe(function(n) {
      test.innerHTML = n + "clicks";
    });
```

少し高度なRxのコードになってしまいました。250ミリ秒以内に二回以上クリックをした時に、`<div id="test">`に2clicksなどと表示するものです。

