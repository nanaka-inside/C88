Title: 冴えないSparkの育て方
Author: @jagaximo

こんにちは！ @jagaximoといいます。
最近、IBMが3500人をSpark関連に投入するというような感じの話題でちょっと盛り上がりを見せているSpark。
でもいざ調べて使ってみようとしても、何ができて、どういううれしみがあるかイマイチ分からない。みたいなことになるかもしれません。
この記事では、Sparkって何？　というのに軽く触れたあと、Sparkをどう始めればいいのか。さらに詰まった時にどうすればいいのかを少し紹介したいと思います。

Sparkって？
=========

OSSの駆け込み寺ことApach Foundationのトップレベルプロダクトの一つで、Hadoopからの流れを汲む、分散処理基盤です。
大きなデータの塊を多数の小さなデータの塊に細かく分割して、それをクラスタの各マシンに渡し、クラスタはそれぞれデータを処理して、最後にマージする、というような手順を踏んで計算します。
この仕組がいわゆるMapReduceです。
HadoopもSparkもこのMapReduceの手順を踏んでタスクを処理する点では同じです。

ではSparkの何が嬉しいのか。Sparkのトップページにいくとこう書いてあります

```
Run programs up to 100x faster than Hadoop MapReduce in memory, or 10x faster on disk.
```

100倍早い。これはSparkがHadoopと違って一回のMapReduceタスクの結果を、それぞれのWorkerのメモリに乗っけるので、HDFSに保存する時のIOコストがかからないためです。
他にも、タスクの記述がHadoopよりも簡単、ビルトインのライブラリが優秀、DAGによる効率的な実行計画などが挙げられますが、ここでは割愛します。検索すれば割と簡単にヒットすると思います。
ここでは簡単にかける上に実行速度が早い分散処理基盤である、ということだけ覚えておけば良いと思います。

Sparkセットアップ
================

Sparkはマシンクラスタを用意して計算させるのが本懐ですが、一つのマシンで動かす事もできます。まずそれで動かしてみましょう

## ダウンロード＆ビルド

いろんな方法がありますが、今回はソースをビルドして動かしてみます。
バージョンはこの記事を書いている時点の最新リリースである1.4.0を使用します。
また、この記事におけるSparkアプリケーションのコードはすべてこの1.4.0を基準に書かれています。

```bash
wget http://www.apache.org/dyn/closer.cgi/spark/spark-1.4.0/spark-1.4.0.tgz
cd spark-1.4.0
build/sbt -Pyarn -Phadoop-2.3 assembly
```
sbtでもmavenでも、ビルドは可能です。今回はsbtを利用しましたが、一回sbtビルドができなくなったまま放置されてた期間があるので、mavenビルドのほうが安全かもしれません

巨大なScalaプロダクトなのでビルドには時間がかかります。ビルドしている間にイカでもプレイして遊んでいればいいと思います

## データを用意する
Sparkは大きなデータを分析するための基盤です。ので、でっかいデータを食わせてみないと始まりません
とはいえ本当に大きなデータを食べさせてもさすがに動かなかったり、時間がかかったりしてだるいので、小さなデータから始めましょう

最初は、ニコニコデータセットのニコニコ大百科データのヘッダデータを使ってみたいと思います。

データの定義は、以下のようになっています

```
カラム: 記事ID, 記事タイトル, 記事ヨミ, 記事種類(a:単語,v:動画,i:商品,l:生放送), 記事作成日時
※ユーザページ、ユーザIDは削除されています。
```

これがCSV形式で入っているようです。
データを落としてみると、年度ごとにCSVが分かれていてめんどくさかったのでマージしちゃいましょう

```bash
cd path/to/data/dir
touch all.csv
ls -1 | grep head | xargs -I{} cat {} >> all.csv
```
データの中身を見ると

```csv
"1","ニコニコ大百科","ニコニコダイヒャッカ","a","20080512173939"
"4","カレー","カレー","a","20080512182423"
"9","ゴーゴーカレー","ゴーゴーカレー","a","20080512183606"
"311","もやしもん","モヤシモン","a","20080513184121"
"312","運営長","ウンエイチョウ","a","20080513185347"
"313","ニワンゴ","ニワンゴ","a","20080513185846"
"314","ニコニコ動画","ニコニコドウガ","a","20080513190203"
"73","新・豪血寺一族 -煩悩解放 - レッツゴー！陰陽師",\N,"v","20080513192636"
"316","支店を板に吊るしてギリギリ太るカレーセット","シテンヲイタニツルシテギリギリフトルカレーセット","a","20080513193502"
"317","アッー!","アッー","a","20080513194056"
```
みたいな内容が続いています。
`"` が非常にうざったいですが、ここでは処理せず、Sparkに読ませるときに処理しようと思います。

ローカルで動作させる
================

## クエリを動かす
クエリはScala, Java, Python, Rでかけます。
今回、僕がScala好きなのでScalaで書いてます。

### spark-shell
ひとまず動かすために、ビルドが終わったSparkのディレクトリへ行き `./bin/spark-shell` をすると、SparkのREPLが立ち上がると思います。
このREPLに対してクエリを打ち込むと使用できると思います

### RDD
SparkはRDDという型で処理したいデータを表現します。平たく言うと、ScalaのListみたいなものです。
このRDDに対してmapなどの処理を行う事で、データを操作して、欲しい情報に加工します。

mapというのは、Scalaやruby, haskellなどの言語に備わっているメソッドで、ここではリストなどのコレクションの全要素に対して、与えた関数の操作を行うものだと考えてください

```scala
import org.apache.spark.rdd.RDD

// 1から1000までの数値が入ったRDDを作成する
val numbers: RDD[Int] = sc.parallelize((1 to 1000).toArray)

// 各要素が与えられ、それに対してどう操作するかを記述する。
// numberは、1, 2, 3...という数値が入っている。これら全てにtoStringを行うことでコレクションの中身をすべて文字列の1, 2, 3...に変換する
val strings: RDD[String] = numbers.map(number => number.toString)
```

これを読んでみるとわかると思いますが、mapの操作は、各要素を並列に計算しても問題がない内容ですね。
MapReduceのmap部分の元ネタになった操作はこれです。平行してできる計算はすべて平行して実行し、各要素が計算するのを待ち合わせてから集約(Reduce)するという操作を連続して行うことで大規模なデータをスケールアウトして計算できるわけです。
もちろん、mapだけではなく、Reduceに関する操作もあります。
また、map, reduce以外にも、それぞれの処理を行うメソッドはあります。
RDDでつかえるメソッドはHishidamaさんがまとめてくださっているページが神がかっていて素晴らしいです。
こちらを参考に、分からない事があったりしたらソースをあたったりしたら良いと思います。

試しに、ワードカウントのクエリを見てみましょう。
これは、一つの英文ドキュメントが与えられた時、その英文に含まれている各単語がいくつか数えるものです。
Spark公式ページにもあるWordCountをそのまま持ってきて、そこにコメントをつけたものです。

```scala
// テキストファイルを読む。hdfsから読んでいるが、ローカルから読むことも可能
// 型はRDD[String]になる。英文の1行が、RDDの1要素になっている
val textFile = spark.textFile("hdfs://...")

// textfileをスペース区切りでsplitして、RDDの1要素を1行から1単語に変換する
val counts = textFile.flatMap(line => line.split(" "))

                // 各要素を(単語、1)のタプルにする
                 .map(word => (word, 1))

                // 要素がタプルの場合、1番めの値をkeyとしてみて、それに対してreduceをかける
                // _ + _ は、key(単語)が同じだった場合、それぞれのvalueを足し合わせる
                // これで、keyごとに、右の値を足しあわせている。これで単語をkeyに、含まれる数をvalueにしたRDDができる
                 .reduceByKey(_ + _)

// カウントした数値を、そのままテキストファイルに保存する
counts.saveAsTextFile("hdfs://...")
```

イメージできたでしょうか？
Scalaプログラマからすれば、手に馴染んだコレクション操作で自由度の高い記述ができるのが魅力的かなと思います。
これをfor文とかに直して記述することは、残念ながらできません。その場合クラスタに処理が分割できないためです。
RDDに対する操作が、各クラスタに分割して計算できる内容になります。

### DataFrame
SparkにはDataFrameという単位でデータを持つこともできます。
これはSparkのビルトインライブラリであるSparkSQLが提供しているモジュールです。
DataFrameは、その場で作るRDBMSのスキーマみたいなものです。
RDDの中に入っているデータに名前を与えて、SQLでクエリを発行することができます。
WordCountをDataFrameにして計算するのはあまりうれしみがないので、違う例を出してみます。
仮に次のようなCSV, `person.csv` を分析する時を考えます。

```csv
John Doe,28
Jane Doe,20
...
```

スキーマとしては `Name,Age` という形になるでしょうか。
このようなデータを分析したいなという時に、DataFrameは便利です。
公式サイトにある例を見てみましょう。

```scala
// SparkContextとSQLContextを作成する
// 今は気にしないでも大丈夫です。
val sc = new SparkContext("local")
val sqlContext = new org.apache.spark.sql.SQLContext(sc)
import sqlContext.implicits._

// case classでスキーマを表現する
case class Person(name: String, age: Int)

// CSVからDataFrameを作成する
val people = sc.textFile("examples/src/main/resources/people.txt").map(_.split(",")).map(p => Person(p(0), p(1).trim.toInt)).toDF()

// SQLを発行できるようにする。
people.registerTempTable("people")

// SQL文を発行する事ができる。
val teenagers = sqlContext.sql("SELECT name, age FROM people WHERE age >= 13 AND age <= 19")

// すべてのPersonのNameをとって標準出力するタスク
// フィールドをPersonクラスで定義した順序でとって来られる
teenagers.map(t => "Name: " + t(0)).collect().foreach(println)

// 上と同じタスク
// こちらはgetAsメソッドを使用してフィールド名で取得している
teenagers.map(t => "Name: " + t.getAs[String]("name")).collect().foreach(println)

// 上と同じタスク
// こちらは、中身をMapに変えている
teenagers.map(_.getValuesMap[Any](List("name", "age"))).collect().foreach(println)
// Map("name" -> "Justin", "age" -> 19)

```
このような感じで、case classのそれぞれの要素をスキーマとして登録してSQLを使い、その後mapなどの処理を通すことができます。
同じデータで様々な分析したいときなどにSQLで問い合わせできる素地作っておくと便利です。
また、SQLを解析する際に簡単な最適化を施してくれるなどの恩恵があるからか、RDDと比較して、安定して高速で動くらしいです。
DataFrameで処理できる場合は、DataFrame化して処理したほうが良さそうです。

RDDとDataFrameは、それについて記事一本かけるくらいに機能があります。
ここで紹介されている以外にもそれぞれのデータの精製方法、加工方法、出力方法などがあるので、気になる場合は公式ドキュメントやScaladoc, ソースなどに当たると良いと思います。

### 月ごとの記事数を、記事種類ごとにカウントする

#### データ整形
簡単なクエリを書いてみましょう。
ここでは、各月ごとにどの種類の記事がどれだけ書かれたかを算出するクエリを書いてみようと思います。
ちなみに `all.csv` のレコード数は203,822ですので、これだったら複雑なことしないのであればローカルマシンでも大丈夫なレコード数です。
まず、ヘッダデータを `Article` として、 `RDD[Article]` なarticlesを作成します。この後articlesを使用する場合はすべてここで定義したものを使用します。
Sparkに最も手早くクエリを動かそうと思った時は、


```scala
import scala.util.Try

val articleText = sc.textFile("file:///Users/jagaximo/data/head/all.csv")

// 記事ID, 記事タイトル, 記事ヨミ, 記事種類(a:単語,v:動画,i:商品,l:生放送), 記事作成月
case class Article(id: Int, title: String, articleType: String, createMonth: Int)

val articles = articleText.map(_.split(",")).map(a => Try{
    // 各文字列の""を取り除いている。
    val splits = a.map(_.init.tail.toString)
    Article(
        splits(0).toInt,
        splits(1),
        splits(3) match {
            case "a" => "word"
            case "v" => "video"
            case "i" => "item"
            case "l" => "live"
        },
        splits(4).take(6).toInt
    )
}).filter(_.isSuccess).map(_.get)
```

TryはScalaにおけるエラーを格納してくれる便利なクラスです。
ここでやっていることを簡単にいうとレコードを読み解いてArticleを生成し、Exceptionが発生したレコードに関しては読み飛ばしています。
この状態での全レコード数は 203,027 とそれなりに減ってしまいましたが、今回は集計を動かしてみることに集中したいので、このまま使っていきます。

#### RDDを使った集計

`articles` を使用して、最初の一歩として、月ごとの全記事数のカウントを行ってみましょう

```scala
// articlesを作成月をキーにして格納する
articles.map(a => (a.createMonth, a))
        // 各キーごとの記事数をカウントする
        .countByKey
        // 出力する
        .foreach(println)
```

あんまり考えていませんでしたが、ほとんどワードカウントと同じになりましたね。違っているのは `countByKey` を使用していることです。
`countByKey` は、キーごとの要素数をカウントしたものを `Map[KeyType, Long]` で返すメソッドです。
つまり、このメソッドを使用した時点で、RDDではなく、集計された通常のデータとなります。
結果はこのようになったと思います。

```
(201106,2378)
(201006,3269)
(201202,3105)
(201308,1629)
(201003,3856)
(200911,4373)
(201102,3344)
(201206,2272)
(200907,4268)
(200812,2679)
(201209,1985)
(201009,4050)
(201110,3022)
...
```

すんなり行きました。
次に本題の月ごとの記事数を記事の種類ごとにカウントしてみましょう。
同じように、countByKeyが利用できれば便利そうなのですが、その場合、月ごとかつ記事種類ごとにどうまとめればいいでしょうか。
実は、このキーはScalaのequalsメソッドでイコールだった場合同じキーとしてみなされます。
そして、Scalaのタプル同士のequalsは、それぞれのタプルの要素に対してequalsされて比較されるので、 `(createMonth, articleType)` をキーにしてしまえば、countByKeyを使って集計できます

```scala
articles.map(a => ((a.createMonth, a.articleType), a))
        .countByKey
        .foreach(println)
```

以下のようになったと思います。

```
((201109,video),190)
((201210,item),36)
((201006,live),1127)
((200904,word),2891)
((201307,item),2)
((200806,live),3)
((200907,video),366)
((201105,item),30)
((201308,word),1324)
...
```

かなり読みづらいですが、一応集計は出来ました。
ちなみに、月ごとにソートされていないのは、countByKeyを使用するとMapになるため、順番の情報が消滅するみたいです。
RDDには `RDD#sortByKey` もしくは `RDD#sortBy` というソートメソッドがありますが、

#### DataFrameを使用した集計

次にDataFrame化してSQLで集計クエリを書いてみましょう
今回は一息に月ごとの記事種類ごとの集計をしてみます。

```scala
import org.apache.spark.sql.SQLContext

val sqlContext = new SQLContext(sc)
import sqlContext.implicits._

articles.toDF.registerTempTable("article")

sqlContext.sql(
  """
    SELECT
      createDate,
      count(articleType='word' or null) word,
      count(articleType='video' or null) video,
      count(articleType='item' or null) item,
      count(articleType='live' or null) live
    FROM
      article
    GROUP BY
      createMonth
    ORDER BY
      createMonth
  """
).collect().foreach(println)

```
結果は以下のようになると思います。

```scala
[200805,2945,367,0,0]
[200806,2848,187,0,3]
[200807,3255,192,0,1]
[200808,3449,243,31,2]
[200809,2898,150,41,4]
[200810,2706,127,28,3]
[200811,2998,215,16,2]
[200812,2426,181,20,52]
[200901,2879,235,17,136]
[200902,2770,166,32,315]
[200903,3193,207,24,433]
...
```

クラスターで動かす
==============

ここからはSparkの本懐であるクラスタ動作を行っていきたいと思います。
ローカルで動かす場合はREPLを起動してクエリを打ち込んでみるだけで良かったですが、クラスタを組んで動かす場合はそうは行きません。
まず、クラスタ構築の方法を説明したあと、クラスタにタスクを流す方法を説明し、簡単だけれど重たい処理をSparkにやらせてみたいと思います。

## クラスタ構築
手っ取り早く動かすだけであれば、実はクラスタの構成情報に関する知識はあまり必要ではないです。
Sparkはec2スクリプトというものを提供しており、これを動かすことでスポットインスタンスとしてSparkクラスタを起動できます。
起動に必要なのはawsのキーペアです。予め作成しておきましょう。
また、ec2スクリプトを使用してクラスタを構築した場合、Standaloneで起動します。
クラスタなのにStandaloneなのは奇妙に感じるかもしれませんが、これはYARNのようなリソースマネージャを利用せず、Spark単体でクラスタを構築する、という程度の意味です。
それらだと何が嬉しいのか、などの話は今回割愛します。

ec2スクリプトの使い方も公式ドキュメントに乗っていますが、ここでも簡単に乗せておきます。

```bash
cd path/to/spark/dir/
./ec2/spark-ec2 -k jagaximo-sandbox -i ~/.ssh/jagaximo-sandbox.pem -s 9 --instance-type=r3.xlarge --region=ap-northeast-1 --spot-price=0.07 launch saenai-spark
```

上のスクリプトをさらっと注釈をつけると、

- jagaximo-sandboxというキーペア名
- jagaximo-sandboxのキーであるspark-test.pemを使用
- slaveの台数を9台
- インスタンスの種別をr3.xlargeを選択
- 東京リージョンを選択
- スポットインスタンスの価格の上限を$0.07に設定
- クラスタの名前をsaenai-sparkとする

以上のような内容でクラスタを構築します。
なお、スレーブは9台ですが、この他にもう一台masterが1つ立つため、合計で10台のスポットインスタンスがこのクエリで立ちます。

## 新たにデータを用意する
クラスタの実験では、ニコニコの動画コメントデータと動画メターデータを用いてみたいと思います。
大百科のヘッダデータと同様、Niiより提供されております。
ニコニコの動画メタデータとコメントデータは、圧縮済みでそれぞれ2.9GB、50GB程度の容量を持つのテキストデータで、膨大です。

## 分析するネタ
まずはどのコメントが最も多いのかのコメントカウントを動かした後、コメントを軸とした、動画のクラスタリングを行いたいと思います。

## 前処理
しかし、ニコニコデータセットのこれらのデータはなかなか扱いにくい形式で出力されているので、今回は前処理を行い、Sparkで扱いやすいように加工します。

まず、コメントデータは、一つのディレクトリに複数の動画IDの名前のファイルがあり、その中に動画IDに紐付いたコメントが並んでいるというような形式をとっています。
これを、ディレクトリ名のファイルの中にある、複数動画のコメントという形式に変換し、コメントのデータに動画IDを埋め込みました。
これは、動画IDがコメントデータに入っていないと、2つのデータをjoinして計算するのが難しいためです。

また、コメントデータ、メタデータ双方とも、以下のような形式になっています。

```
{"date":1174594657,"no":1,"vpos":4443,"comment":"\u4e0d\u601d\u8b70\u306a\u8e0a\u308a\u3092\u8e0a\u3063\u305f\uff01","command":""}
{"date":1174594960,"no":2,"vpos":15932,"comment":"\u3066\u304b\u8e74\u308b\u307e\u3067\u3046\u3054\u3044\u3061\u3083\u3044\u3051\u306a\u3044\u3093\u3058\u3083\u306a\u3044\u306e\uff1f","command":""}
{"date":1174595040,"no":3,"vpos":23905,"comment":"\u3069\u3045\u3067\u304f","command":""}
{"date":1174595106,"no":4,"vpos":27013,"comment":"\u3067\u3045\u3067\u304f","command":""}
{"date":1174595111,"no":5,"vpos":27525,"comment":"\u3058\u30fc\u3060","command":""}
{"date":1174595158,"no":6,"vpos":32266,"comment":"\u30c7\u30e5\u30c7\u30af","command":""}
...
```
これはarrayのデータであると解釈できるので

```json
[
  {"date":1174594657,"no":1,"vpos":4443,"comment":"\u4e0d\u601d\u8b70\u306a\u8e0a\u308a\u3092\u8e0a\u3063\u305f\uff01","command":""},
  {"date":1174594960,"no":2,"vpos":15932,"comment":"\u3066\u304b\u8e74\u308b\u307e\u3067\u3046\u3054\u3044\u3061\u3083\u3044\u3051\u306a\u3044\u3093\u3058\u3083\u306a\u3044\u306e\uff1f","command":""},
  {"date":1174595040,"no":3,"vpos":23905,"comment":"\u3069\u3045\u3067\u304f","command":""},
  {"date":1174595106,"no":4,"vpos":27013,"comment":"\u3067\u3045\u3067\u304f","command":""},
  {"date":1174595111,"no":5,"vpos":27525,"comment":"\u3058\u30fc\u3060","command":""},
  {"date":1174595158,"no":6,"vpos":32266,"comment":"\u30c7\u30e5\u30c7\u30af","command":""},
  ...
]
```

のようなデータに整形しました。
