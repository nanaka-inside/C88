Title: ESS「エクストリームリー・ストイック（サディスティック）・スクレイピング」
Subtitle: POSIX原理主義者が教える恐怖のスクレイピング
Author: @richmikan
Author(romaji): Rich Mikan

<!-- 元ネタ http://qiita.com/richmikan@github/items/024b1f3869c84b9a3a21 -->
<!-- 記法   https://github.com/naoya/md2inao                             -->


# ESS「エクストリームリー・ストイック（サディスティック）・スクレイピング」

説明しよう。この記事は、POSIX原理主義で世のプログラマーを洗脳し、世界征服を目論む「秘密結社シェルショッカー」の日本支部長、リッチー大佐が、何の言語もライブラリーも使わず、どのUNIXにも最初から入っているsedやAWKといっコマンドだけでHTMLを読み解くという、ベリィ・サディスティックなスクレイピングを見せつける記事なのだ！

## 本の姿をした怪人を書店へ送り込んだ！

　全世界70垓人のプログラマーどもよ、ごきげんよう。私は偉大なる秘密結社シェルショッカーの日本支部長、リッチー大佐である。今日の話を始める前に一つ我々の侵略活動の一端を見せてやろう。

![怪人「すべてのUNIXで20年動くプログラムはどう書くべきか」男](images/pfb_otoko.jpg)

> **「すべてのUNIXで20年動くプログラムはどう書くべきか」男**

　という怪人を我々の日本支部の管内である日本全国の書店に送り込んだのだ。本来であれば正々堂々と世界征服をしたいところだが、書店員の目を欺くために、この私が世を忍ぶ仮の名前を使って製造したのだ。書店のコンピューター書売り場を見てくるがいい。訪れた客たちが、新たに我ら組織の思想に洗脳されていく様を！

　メトロパイパー男による侵略は、東京メトロイダーの手引きにより奇しくも失敗しおったが、今度こそ成功させてやる。見ておれぇぇ！


## 今日は究極のスクレイピングだ

　さて、今日お前たちに見せてやるのは、シェルショッカー流のWebスクレイピングテクニックだ。

　Webは今や、世界征服を実行するうえで欠かせない存在となった。Webメディアに群がる人間どもを洗脳するためにも重要であるが、その前に、作戦を立案すべく諜報活動を行うための重要な情報源でもある。その第一歩は、人間どもが何の危機感も抱かず公開しているWebページのスクレイピングである。

　ではそのスクレイピングをどうやるか。何、DOMライブラリーだとぉ？誰だ、今そのセリフを口にしたやつは！そんなものを使ったら、POSIX原理主義を崇拝する我らが世界征服をする意味がなくなってしまうではないか。どうやらお前達はまだ、洗脳が足りておらんようだな。よぅし、ならば早速スクレイピングの奥義を目に焼き付けさせてやる！

## スクレイピングの秘密兵器

　DOMライブラリーなんぞ使わんと言ったが、かといって丸腰というわけではないぞ。スクレイピングのために、POSIX原理主義を厳格に守りながら開発した秘密兵器が我々にはある。[Parsrシリーズ](https://github.com/ShellShoccar-jpn/Parsrs)と名付けた各種テキストフォーマットパーサーのうちXMLパース用に開発した「X」こと[**parsrx.sh**](https://github.com/ShellShoccar-jpn/Parsrs/blob/master/parsrx.sh)が使える。前回（メトロパイパー男の回）でも説明したが、もう一度説明してやろう。

　こいつの威力は絶大だ！例えば次のようなXMLがあったとする。

```
<文具購入リスト 会員名="文具 太郎">
  <購入品>はさみ</購入品>
  <購入品>ノート(A4,無地)</購入品>
  <購入品>シャープペンシル</購入品>
  <購入品><取寄商品>替え芯</取寄商品></購入品>
  <購入品>クリアファイル</購入品>
  <購入品><取寄商品>６穴パンチ</取寄商品></購入品>
</文具購入リスト>
```

　これを我らのXMLパーサーにかければこうなる。

```
/文具購入リスト/@会員名 文具 太郎
/文具購入リスト/購入品 はさみ
/文具購入リスト/購入品 ノート(A4,無地)
/文具購入リスト/購入品 シャープペンシル
/文具購入リスト/購入品/取寄商品 替え芯
/文具購入リスト/購入品
/文具購入リスト/購入品 クリアファイル
/文具購入リスト/購入品/取寄商品 ６穴パンチ
/文具購入リスト/購入品
/文具購入リスト \n  \n  \n  \n  \n  \n  \n
```

　元のXMLデータにはもちろん各種の値が格納されているわけだが、それぞれの値がどのタグや属性の中に格納されているかが重要だ。タグは階層構造をとっているのでファイルの格納場所をパスで表現するのと同様に、XML用のパスで表現する方法がある。それが**XPath**と呼ばれるものだ。このXPathを、値の手前に添えながら1つの値を1行で表現している(値の中に改行があるものは`\n`で表現する)。

　XPathでは、タグの入れ子構造はスラッシュ`/`で表現し、タグの中の属性名はその手前に`@`を付けることによって表現する。この規則を踏まえて元のXMLと上記のXPathを見比べれば、その関係は容易に理解できるな。

　こうすると何が嬉しかといえば、UNIXコマンドで好きなように料理できるようになるということだ。例えば、店に並んでいない取り寄せ商品の一覧が知りたければ、パース後のテキストデータに対して`grep '取寄商品' parsed_data.txt`などと書けばよい。さらに、それが何個あったか知りたければ`grep '取寄商品' parsed_data.txt | wc -l`と、後ろにパイプでコマンドを繋げばよい。UNIXコマンドとの相性もばっちりではないか。

### 28個のPOSIXコマンドでできている

　parsrx.shがどうやって変換しているかについての説明は省略するが、cat、sed、AWK、trという4種類のコマンドを計28個、パイプで繋いでいるだけだ。だから、ワンライナーで書こうと思えば書けなくもない。嘘だと思うならソースコードを見てくるがいい。

```
https://github.com/ShellShoccar-jpn/Parsrs/blob/master/parsrx.sh
```

　そしてもちろん、上記のコマンドはPOSIXの範囲で使えるオプションや機能しか用いていない。我らはPOSIX原理主義を崇拝しているからな。


## ターゲットはどいつだ

　さぁて、ではどのWebページを我らのスクレイピングの餌食にしてやろうか……。

> 「大佐！[ニコニコ静画](http://seiga.nicovideo.jp/)」なんてどうでしょうか。

ほほぅ、いかがわしいイラストを押し込めるために「春」というJailのあるアレか。