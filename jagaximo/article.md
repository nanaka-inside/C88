Title: 冴えないSparkの育て方
Author: @jagaximo

こんにちは！ @jagaximoといいます。
最近、IBMが3500人をSpark関連に投入するというような感じの話題でちょっと盛り上がりを見せているSpark。
でもいざ調べて使ってみようとしても、何ができて、どういううれしみがあるかイマイチ分からない。みたいなことになるかもしれません。
この記事では、Sparkって何？　というのに軽く触れたあと、Sparkをどう始めればいいのか。さらに詰まった時にどうすればいいのかを少し紹介したいと思います。

Sparkって？
=========

OSSの駆け込み寺ことApach Foundationのトップレベルプロダクトの一つで、Hadoopからの流れを汲む、分散処理基盤です。
大きなデータの塊を多数の小さなデータの塊に細かく分割して、それをクラスタの各マシンに渡し、クラスタはそれぞれデータを処理して、最後にマージする、というような手順を踏んで計算します。この仕組がいわゆるMapReduceです。
HadoopもSparkもこのMapReduceの手順を踏んでタスクを処理する点では同じです。

ではSparkの何が嬉しいのか。Sparkのトップページにいくとこう書いてあります

```
Run programs up to 100x faster than Hadoop MapReduce in memory, or 10x faster on disk.
```

100倍早い。これはSparkがHadoopと違って一回のMapReduceタスクの結果を、それぞれのWorkerのメモリに乗っけるので、HDFSに保存する時のIOコストがかからないためです。
他にも、タスクの記述がHadoopよりも簡単、ビルトインのライブラリが優秀、ライブラリの作りやすさなどが挙げられますが、ここでは割愛します。検索すれば割と簡単にヒットすると思います。

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

今回は、ニコニコデータセットのニコニコ大百科データのヘッダデータを使ってみたいと思います。

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

## クエリを書く
クエリはScala, Java, Python, Rでかけます。
今回、僕がScala好きなのでScalaで書いてます。

### RDD
SparkはRDDという型で処理したいデータを表現します。平たく言うと、ScalaのListみたいなものです。
このRDDに対してmapなどの処理を行う事で、データを操作して、欲しい情報に加工します。

mapというのは、Scalaやruby, haskellなどの言語に備わっているメソッドで、ここではリストなどのコレクションの全要素に対して、与えた関数の操作を行うものだと考えてください

```scala
// 1から1000までの数値が入ったRDDを作成する
val numbers: RDD[Int] = spark.parallelize((1 to 1000).toArray)

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

ニコニコ大百科のデータを解析する前に、試しに、ワードカウントのクエリを書いてみましょう。
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
DataFrameは、その場で作るRDBMSのスキーマみたいなものです。
RDDの中に入っているデータに名前を与えて、SQLでクエリを発行することができます。
WorｄCountを書き換えて、DataFrameとSQLで記述してみます

```scala
```



### 書き置き

```scala
import sys.process._
import sqlContext.implicits._
import scala.util.Try

val zeppelinHome = ("pwd" !!).replace("\n", "")
// val bankText = sc.textFile(s"file:///Users/jagaximo/data/head/all.csv")

val articleText = sc.textFile("file:///Users/jagaximo/data/head/all.csv")

// 記事ID, 記事タイトル, 記事ヨミ, 記事種類(a:単語,v:動画,i:商品,l:生放送), 記事作成日時
case class Article(id: Int, title: String, articleType: String, createDate: Long)

val articles = articleText.map(_.split(",")).map(a => Try{
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
        splits(4).take(6).toLong
    )
}).filter(_.isSuccess).map(_.get).toDF

articles.registerTempTable("article")


%sql
select createDate, count(articleType="word" or null) word, count(articleType="video" or null) video, count(articleType="item" or null) item, count(articleType="live" or null) live
from article
group By createDate
order by createDate
```
