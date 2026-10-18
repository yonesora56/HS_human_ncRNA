<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# @GitHub @Academic

「bigWigAverageOverBed」というツールがどういうふうに使われているか知りたいので、事例を網羅的に調査してください

得られた情報で十分な調査ができたので、包括的な回答を作成します。

***

## `bigWigAverageOverBed` の使用事例 — GitHub上の網羅的調査

`bigWigAverageOverBed` は UCSC kentUtilsに含まれるコマンドラインツールで、**bigWigファイルのシグナルをBEDファイルで指定したゲノム区間ごとに集計（平均・最大・最小など）する**ツールです。基本構文は以下の通りです。

```bash
bigWigAverageOverBed in.bw in.bed out.tab
```

出力は `name`, `size`, `covered`, `sum`, `mean0`, `mean`（カバーされた塩基のみの平均）の6カラムです。

***

## 主要オプション

| オプション | 説明 |
| :-- | :-- |
| `-bedOut=out.bed` | 入力BEDに mean カラムを追加した出力BEDを作成 |
| `-sampleAroundCenter=N` | BED区間の中心から±N/2 bpの範囲でサンプリング（ピークサミット中心解析に最適） |
| `-minMax` | 最大値・最小値の追加カラムを出力 |
| `-stats=stats.ra` | 全体統計をRAファイルに出力 |


***

## GitHubで確認された使用事例カテゴリー

### 1. ヒストン修飾シグナルの定量（ChIP-seq）

最も多い使われ方で、ChIP-seqのfold-change bigWigからゲノム区間ごとのヒストン修飾量を取り出す用途です。

**事例：IDH変異グリオーマの解析（[wangxinyush/IDH_phUMR](https://github.com/wangxinyush/IDH_phUMR)）**

```bash
bigWigAverageOverBed -bedOut=brain2_${histone[i]}.bed \
  $brain2_file ./hg19_CGI_bed4.bed brain2_${histone[i]}.tab
```

CGI（CpGアイランド）領域上でH3K27ac等のヒストン修飾シグナルを定量し、IDH変異グリオーマと正常脳のBoxplot比較に利用しています。

**事例：ENCODE FCC プロジェクト（[ReddyLab/Proj_ENCODE_FCC](https://github.com/ReddyLab/Proj_ENCODE_FCC)）**
ChIP-seq ヒストン修飾のBigWigに対してENCODEのFCC区間をBEDで与え、各領域のシグナル平均値を計算しています。

**事例：ENCODE maous development（[SoFairOA/Dataset](https://github.com/SoFairOA/Dataset) 内の論文記述）**

```
Each peak was then scored using ChIP-seq fold enrichment over input in each stage using bigWigAverageOverBed, then quantile normalized across stages
```

72組織ステージにわたるH3K27acデータを各ピークに定量後、ステージ間でquantile normalizationする前処理に使われています。

***

### 2. ENCODE/SCREEN によるシス調節エレメントのZ-score正規化

**事例：[weng-lab/SCREEN2.0](https://github.com/weng-lab/SCREEN2.0)（ENCODE cCRE分類）**

```
We used the UCSC tool bigWigAverageOverBed to compute the signal for each rDHS for a 
DNase, H3K4me3, H3K27ac, or CTCF experiment.
```

- DNase / CTCF：rDHS 区間内で平均シグナルを計算
- H3K4me3 / H3K27ac：rDHS ± 500 bp の拡張領域で計算（フランキングヌクレオソームを考慮）
- その後 log10変換してZ-scoreを算出し、cCREのバイオケミカル分類に利用

***

### 3. ATAC-seqの品質管理（QC）

**事例：[kundajelab/ataqc](https://github.com/kundajelab/ataqc) / [DoaneAS/atacflow](https://github.com/DoaneAS/atacflow)**

```python
bw_average_over_bed = 'bigWigAverageOverBed {0} {1} {2}'.format(
                        bw_file, regions_file, out_file)
```

ATACパイプラインのQCモジュールで、ATAC-seq bigWig（p値/fold changeトラック）をピーク領域のBEDに対して適用し、各サンプルの領域ごとの平均シグナルを求めています。Stanford Kundaje labが開発した `ataqc` では、この値でサンプル間のQCスコア比較を行っています。

**事例：[kundajelab/training_camp](https://github.com/kundajelab/training_camp)**

```
We use the bigWigAverageOverBed utility to compute the mean signal from the pval tracks 
and the mean signal from the fold change tracks for each genomic region in each sample.
```

ATACパイプラインのトレーニング教材でも標準ステップとして組み込まれています。

***

### 4. 進化的保存スコアの計算（PhastCons / PhyloP）

bigWig形式のPhastCons/PhyloP保存スコアを任意の調節領域に適用するのも頻用パターンです。

**事例：[pfenninglab/OCROrthologPrediction](https://github.com/pfenninglab/OCROrthologPrediction)**

```bash
bigWigAverageOverBed \
  -bedOut=*_conservationPhastConsPlacental.bed \
  -sampleAroundCenter=500 -minMax \
  mm10.60way.phastCons60wayPlacental.bw stdin output.tab
```

ATAC-seqのピークサミットを中心に±250 bpでPhastCons（胎盤類哺乳類60-way）を計算。機械学習モデルの特徴量として利用しています。

**事例：[OpenEvalProject/evals](https://github.com/OpenEvalProject/evals)内の論文（elife-76500）**

```
For each CRE, we computed a phastCons score for a 150 bp window centered on the 
ATAC-seq summit using the bigWigAverageOverBed script from UCSC Tools (Version 3.6.3).
```

マウスmm10の60脊椎動物PhastCons保存スコアを各CREの150 bp ウィンドウで定量し、allele-specific CREと共有CREの保存性比較に利用しています。

**事例：[AndrejAngelovski/deep_seek_hackathon](https://github.com/AndrejAngelovski/deep_seek_hackathon)の論文（PMC8206121）**

```
Mean PhastCons scores for all analyzed intervals were calculated with bigWigAverageOverBed 
from the kentUtils package (https://github.com/ENCODE-DCC/kentUtils).
```

活性プロモーターとエンハンサーの保存スコアを計算し、ランダム領域との比較（Mann–Whitney U検定）を実施しています。

***

### 5. スプライシング・エクソン保存性解析

**事例：[boschresearch/Pap2Pat](https://github.com/boschresearch/Pap2Pat)**

```
we used bedtools bigWigAverageOverBed to determine the average conservation 
over the spliced region.
```

NMDを引き起こすエクソン、通常の選択的スプライシングエクソン、構成的エクソンの3グループでhg38 PhastCons保存スコアを比較し、density plotで可視化しています。

***

### 6. ABC (Activity-by-Contact) モデルのエンハンサー定量

**事例：[Zaki-1052/mariner_hi-c](https://github.com/Zaki-1052/mariner_hi-c)（ABC モデル実装）**

```
use bigWigAverageOverBed on H3K27ac bigWigs to quantify signal at consensus enhancers, 
then integrate into ABC scoring outside the Snakemake pipeline.
```

Engreitz らのABCモデルでのエンハンサー活性定量ステップとして、H3K27ac bigWig × エンハンサーBEDの組み合わせで使われています。

***

### 7. 変異背景率（Somatic Mutation Rate）の分析

**事例：[eyamrog/cl_st2_eyamrog](https://github.com/eyamrog/cl_st2_eyamrog)内の論文（Cell掲載）**

```
we calculated the standard deviation of each covariate's value within each bin using 
the bigWigAverageOverBed tool available from UCSC's genome utilities
```

ゲノムを500kb〜1kbの可変ウィンドウで分割し、DNA複製タイミング・GC含量・DHS感受性などの共変量の空間的変動を`bigWigAverageOverBed`で算出。体細胞変異背景率のモデリングに使用しています。

***

### 8. 心臓エンハンサーのエピゲノム特徴量計算

**事例：[OpenEvalProject/evals](https://github.com/OpenEvalProject/evals)内の論文（elife-10557）**

```
we averaged the wig signal tracks over every enhancer with the UCSC bigWigAverageOverBed tool. 
Fold difference in signals between QT/QRS enhancers and all LV enhancers were calculated 
by comparing the median signal values of the two groups.
```

QT/QRS間隔に関わる心室エンハンサー vs 全LVエンハンサーのヒストン修飾シグナルをMedian比較し、Mann-Whitney U検定で有意差を評価しています。

***

### 9. Haystack / haystack_bio（ホットスポット検出）

**事例：[lucapinello/Haystack](https://github.com/lucapinello/Haystack) / [pinellolab/haystack_bio](https://github.com/pinellolab/haystack_bio)**
ChIP-seq / DNase-seq / ATAC-seq / RRBS-seq のbigWigを複数サンプルにわたってゲノム区間ごとに定量するため、内部でbigWigAverageOverBedを呼び出しています。細胞型特異的「ホットスポット」の検出とTFモチーフ解析に使用されています。

***

### 10. 単細胞・TSSエレメントの定量（sc-end5-seq）

**事例：[chung-lab/SCAFE](https://github.com/chung-lab/SCAFE)**
シングルセルRNA-5'end-seqデータからtCRE（転写されたシス調節エレメント）を抽出するパイプラインの依存ツールとして明示的に記載されています。プロモーター・エンハンサー活性の定量ステップで利用されています。

***

## 使用パターンのまとめ

| カテゴリー | 入力bigWig | 対象BED | 主な目的 |
| :-- | :-- | :-- | :-- |
| ChIP-seq 定量 | H3K27ac, H3K4me3 などのFold-change | ピーク/CGI/TAD | Z-score、ヒストン定量比較 |
| ATAC-seq QC | p値/fold-change トラック | ATACピーク | サンプルQCスコア |
| 保存性スコア | PhastCons, PhyloP | CRE/エクソン | 進化的保存性の評価 |
| 変異解析 | DHS、複製タイミング | ゲノムビン | 体細胞変異背景率モデリング |
| ABCモデル | H3K27ac | エンハンサー候補 | Activity定量 |
| 機械学習特徴量 | 各種エピゲノム | OCR/ピーク | モデル入力特徴量 |

GitHub上では総計278件以上のコードでbigWigAverageOverBedへの言及が確認され、ENCODE-DCC/kentUtilsを経由したbiocondaパッケージ（`ucsc-bigwigaverageoverbed`）として広く配布されています。Rust製の代替実装 [jackh726/bigtools](https://github.com/jackh726/bigtools) もbigWigAverageOverBed互換のインターフェースを提供しており、高速化の選択肢として注目されています。

