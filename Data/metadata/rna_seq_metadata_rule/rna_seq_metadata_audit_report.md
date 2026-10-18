# ヒト熱ストレス RNA-seq メタデータの監査結果（調査停止時点）

作成日：2026年9月13日。ユーザーの指示により追加調査を停止し、取得済みの証拠で整理した結果です。実験操作の手順は本レポートに含めていません。

対象は **405比較行・177列、52 BioProject、49 DOI** です。1行は熱ストレス側Runと対照側Runの比較ペアであり、405人・405独立生物学的反復を意味しません。元ファイルは変更していません。

カラム統合、文献・登録情報照合、表記統一、メーカー資料確認の順に実施しました。メーカー資料からの判断と、実際のリードで確認した鎖特異性は区別しています。FASTQ/BAMによる実測は行っていません。

## 出力ファイル

- [修正版メタデータ TSV](rna_seq_metadata_curated_20260913.tsv)：405行・167列。安全な統合で23列を削減し、監査情報13列を追加。
- [カラム統合候補 TSV](column_merge_candidates.tsv)：38候補。代表列、統合候補列、採用可否、理由、競合の実測。
- [ライブラリー名の統一案 TSV](rna_library_name_mapping.tsv)：原記載44種類の対応表。
- [文献・ライブラリー監査 TSV](rna_library_audit.tsv)：49 DOIの判定、修正値、根拠、出典、注意点。
- [カラム統合の履歴 TSV](column_merge_provenance.tsv)：統合に関係した元値を405行すべて保存。

## 1. カラム統合候補

19組は、同一値または意味を変えない正規化で統合できました。欠損を補完し、Run・Experiment・BioSample・GEO Sample・Studyの階層と、熱側／対照側の順序を維持しています。条件付き候補と非統合列は修正版に残しています。

| 代表列 representative_column | 統合できるカラムのリスト | 判定・修正版への適用 | 根拠・条件 |
| --- | --- | --- | --- |
| sample_geo_accession | sample_geo_accession; gsm_id; library_name_right | 安全／適用 | gsm_idは355行完全同一。library_name_rightはGSE285497の52行すべてGSM IDであり実体はGEO sample accession。一般のlibrary_nameとは統合しない。 |
| gse_id | gse_id; sample_series_id | 安全／適用 | 重複記入0行、sample_series_idが6行を補完する。gse_idの複数Series記載を削らない。 |
| gse_id | gse_id; study_alias | 条件付き／未適用 | study_aliasはDRP、E-MTAB、UUID、PRJNA、PRJCA等を混在。gse_idとの重複349行のうち25行は複数GSE対単一GSE等の差。全列coalesce不可。 |
| experiment_accession | experiment_accession; srx; sra | 安全（URL抽出後）／適用 | srxは134行完全同一。sraは6行全てSRX URLで番号抽出後一致。submission_accessionとは階層が違う。 |
| sample_accession | sample_accession; biosample | 安全（URL抽出後）／適用 | biosampleは6行のSAMN URLで番号抽出後既存値と一致。secondary_sample_accessionとはID体系が違うため統合しない。 |
| run_accession | run_accession; accession | 安全／適用 | run_accessionとaccessionの重複記入0行。sample_heat_id/control_idは対照の役割を持つため別列を保持。 |
| run_accession | run_accession; srr | 条件付き／未適用 | 重複134行中82行一致、52行srr=multi。multi情報を無言で削除しない。 |
| organism | sample_organism_ch1; organism; scientific_name | 安全／適用 | 全て有効値はHomo sapiens。taxonomyの名称でありtax_idと別概念。 |
| tax_id | sample_taxid_ch1; tax_id | 安全／適用 | 有効値は全て9606。tax_lineageは祖先分類群の列挙のため維持。 |
| instrument_model | sample_instrument_model; instrument_model | 安全（既知表記変換後）／適用 | 重複355行のうち17行がこのメーカー名有無のみ。instrument_platformはプラットフォーム分類で別保持。 |
| library_source | sample_library_source; library_source | 安全（大小文字正規化後）／適用 | 重複355行全てcasefold一致。library_source=GENOMICの12行は表記統合でTRANSCRIPTOMICに書き換えず別途監査。 |
| library_strategy | sample_library_strategy; library_strategy; library_strategy_right | 安全（大小文字正規化後）／適用 | 重複する値に実質競合なし。ssRNA-seqという戦略表記だけでstrandnessを決めない。 |
| library_selection | sample_library_selection; library_selection; protocol | 条件付き／未適用 | sample_library_selection/library_selection重複355行のうち2行GSE191134でcDNA対PCR。library_construction_protocolとは統合不可。 |
| library_layout | library_layout; read_type | 安全／適用 | 重複134行すべて一致。strandnessとは別属性。submitted_read_typeはファイル単位でPAIRED;PAIRED等の多値につき直接統合しない。 |
| experiment_title | experiment_title; description | 安全／適用 | 391行完全同一。sample_descriptionとは実体階層が違う。 |
| sample_title | sample_title; sample_description_right | 安全（空白正規化後）／適用 | sample_description_right有効152行すべてsample_titleと空白正規化後一致。sample_descriptionへは統合しない。 |
| sample_title | sample_title; sample_title_right | 条件付き／未適用 | 重複248行中生値10行差、空白正規化後も4行差。GSE191134でRep2対biological replicate 2等、GSE285497でセミコロン対空白。 |
| study_title | study_title; project_name | 条件付き／未適用 | 重複389行で45行差。project_name=Homo sapiensは43行で研究名ではなく生物種。study_titleを単純上書きしない。 |
| cell_type | cell_type; cell_type_right | 安全／適用 | 重複100行すべて一致。細胞株IDを表すcell_lineとは統合しない。 |
| cell_line | cell_line; cell_line_right | 条件付き／未適用 | 重複206行中2行GSE191134でHeLa cells対HeLa S6。単純に左優先するとS6情報が失われる。 |
| strain | strain; strain_right | 安全／適用 | 重複12行すべてHEK293T。列名はstrainだが本表は細胞株名が入るためcell_lineへの再分類は別検証。 |
| isolate | isolate; isolate_right | 安全／適用 | 重複1行HTB-22で一致。cell_lineやstrainとの無条件統合は行わない。 |
| tissue | tissue; tissue_type; tissue_cells | 条件付き／未適用 | tissue/tissue_type重複30行一致だがhuman embryonic kidney cells、HeLa由来記述等を含み細胞型と解剖部位が混在。 |
| reference_genome | assembly; genome_build | 条件付き／未適用 | 重複記入0行。GRCh38.105やGRCh38.91を単にhg38に潰さない。Homo sapiens（種名）とmm9（マウス）が混在するため参照ゲノムとしての妥当性監査が必要。 |
| supplementary_files | sample_supplementary_file_1; sample_supplementary_file_2; sample_supplementary_file_3 | 条件付き（リスト化）／未適用 | 同じ値を表す冗長列ではなくlane等が異なる複数ファイル。coalesceは情報欠落。NONEは補足ファイル無しを表す明示値として扱う。 |
| submitted_ftp | submitted_ftp; submitted_galaxy | 安全／適用 | 9行完全同一。submitted_asperaは転送方式が違うため別保持または方式名付きリンクオブジェクトに。 |
| bam_ftp | bam_ftp; bam_galaxy | 安全／適用 | 6行完全同一。bam_asperaは方式が異なる。 |
| fastq_ftp | fastq_ftp; fastq_galaxy | 安全／適用 | 6行完全同一。fastq_asperaは方式が異なる。 |
| treatment_description | treatment; condition; stress; sample_group; treatment_conditions; sample_treatment_protocol_ch1 | 条件付き（出典付きリスト化）／未適用 | treatment/conditionの重複6行はsiRNA条件対温度条件で全行違う。単純coalesce不可。熱温度・対照温度・熱時間は別属性を維持。 |
| time_description | time; timepoint; stress treatment time | 非統合／未適用 | timeには120 vs 30,150 vs 30,3.5 hr。timepointには4 h vs 0 h (untreated)。stress treatment timeへ統合すると対照側時間や回復時間を失い得る。 |
| molecule_description | sample_molecule_ch1; molecule; fraction | 非統合／未適用 | moleculeの4行はTotal fragmented RNAでtotal RNAより加工情報が多い。fractionはPolysome associated RNA等で分画を示す。 |
| sample_and_experiment_aliases | sample_alias; experiment_alias; library_name; library_name_right; run_alias; sample_name; column | 非統合／未適用 | sample_aliasはGSM以外にSAMDや自由名、experiment_aliasもGSMとDRX等が混在。library_name_rightがGSM重複であることは別の安全候補に記載。 |
| dates | sample_submission_date; sample_last_update_date; last_updated; first_created; first_public; collection_date; collection_date_start; collection_date_end | 非統合／未適用 | GEO提出日・GEO更新日・アーカイブ作成公開日・試料採取日は異なる。collection_date=2016の開始終了への展開は日精度の実測値ではない。 |
| status | sample_status; status | 非統合／未適用 | sample_statusはPublic on Oct 15 2024など。statusはpublic。日付を削るcoalesceは情報欠落。 |
| sample_provenance | sample_contact_country; country; sample_contact_institute; center_name; Biomaterial Provider | 非統合／未適用 | 名称が似ていても対象が違う。countryのFrance2行を研究者所在国に混ぜない。 |
| accession_hierarchy | sample_heat_id; sample_control_id; sample_geo_accession; sample_accession; secondary_sample_accession; experiment_accession; run_accession; gse_id; study_accession; secondary_study_accession; submission_accession; Individual Accession | 非統合／未適用 | 対になったheat/controlの順序も維持。異なるIDが同一対象にリンクしていても代替同義列とは限らない。 |
| sequencing_quantities | read_count; base_count; Read length for mate1(bp); Read length for mate 2(bp); nominal_length; nominal_sdev; fastq_bytes; sra_bytes; bam_bytes; submitted_bytes | 非統合／未適用 | read数、塩基数、読長、インサート長推定、バイト数は別属性。mate1/2が現在同じ150でも片方削除しない。 |
| replicate_identifiers | biological_replicates; replicate; batch | 条件付き/一部非統合／未適用 | 反復数と反復番号を区別する。現表biological_replicatesはbiological replicate_1等で番号。別プロジェクトreplicateの1/2の型は追加確認が必要。 |

`sample_geo_accession`と`gsm_id`は355行、`experiment_title`と`description`は391行で完全一致しました。`library_name_right`は52行すべてGSMアクセッションで、一般のlibrary nameとは別扱いにしました。`sample_description_right`はsample titleの重複であり、本文説明を持つ`sample_description`とは統合していません。

`sample_library_selection`と`library_selection`にはcDNA／PCRの食い違いが2行あります。日付の対象DB、採取日と公開日、処理時間と回復時間、分画とRNA分子種、read数とbase数などは別概念のため保持しました。全ての値が同じ定数列も、同義カラムでない限り削除していません。

## 2. rna_library の文献・登録情報との照合

TogoMCPのPubMed RDF照会で49 DOIを検索し、47件の書誌情報を取得しました。この照会は文献の同定に使用し、製品名の根拠はGEOの該当サンプル、論文本文、補足資料から確認しました。49件すべてに判定を付けていますが、未解決・不一致も含みます。

| 判定 | DOI件数 | 比較行数 | 意味 |
| --- | --- | --- | --- |
| 確認済み | 29 | 210 | 対象試料に使われた製品名を支持 |
| 修正 | 10 | 159 | 会社名・抽出試薬の混同訂正、具体的作製キットや方法の補完を含む |
| 部分的に支持 | 6 | 23 | 製品系列または記載の一部のみ支持 |
| 未解決 | 2 | 4 | 対象試料の具体的キットが未確定 |
| 不一致あり | 2 | 9 | DOI対応または製品記載に不一致 |

### 重要な訂正と保留

- **P08／GSE259306（58行）**：「Bioyi」はキット名として不適切。対象RNA-seqではNEBNext Ultra II Directionalが確認されました。元会社名は当該研究の委託先としても裏付けられず、原記載の履歴に保存しました。[資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC12327812/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113675) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113720) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113661) / [資料5](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113659)
- **P24／GSE285497（52行）**：RNeasyは抽出用で、作製キットはNEBNext Ultra RNAです。元DOIは別論文を指しており、GEOが紐付ける文献の候補を`reference_doi_suggested`に記載しました。原DOIは保持しています。[資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8703440) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8703439) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE285497) / [資料4](https://pubmed.ncbi.nlm.nih.gov/38484921/) / [資料5](https://pubmed.ncbi.nlm.nih.gov/41314531/)
- **P13／GSE189578（3行）**：GEOはTruSeq RNA系列を支持しますが、入力DOIは別研究を指す疑いが強く、Stranded型への置換はしていません。代替DOIは未確定です。[資料1](https://www.nature.com/articles/s41467-024-51258-0) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5704146) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5704143) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189578)
- **P37／GSE222110（6行）**：GEOはTruSeq Stranded mRNA、論文はTruSeq RNA Sample Prep v2を記載。修正版はキットをunknown、鎖判定をconflictingとしました。[資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6914924) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6914918) / [資料3](https://www.nature.com/articles/s41467-023-43262-7)
- **P07（15行）**：Bioyiは会社名。GSE271918では委託先として支持されますが、GSE247417の6行はDOI対応を十分確認できず、委託先列を空欄にして保留しました。具体的キットはunknownです。[資料1](https://advanced.onlinelibrary.wiley.com/doi/10.1002/advs.202309588) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7889752) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE247417) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8389003) / [資料5](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8389000) / [資料6](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC11481226/supplementaryFiles)
- **P09・P11・P19・P22・P25**：Direct-zol、miRNeasy、RNA Clean & Concentrator、RNA Microprepは抽出・精製用であり、作製キットから分離。具体的な作製製品が不明ならunknownにしています。
- **P20**：同じ論文の別データセットに書かれたTruSeq製品を対象熱ストレス試料に割り当てる根拠が不足し、unknownにしました。[資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3755850) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3755856) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC7170965/)
- **P31・P40・P47**：未記入／unknownから、それぞれMSR-seqの独自法、SMARTer v2、TruSeq RNA系列まで補完。ただしP47は版と鎖特異性が未確定です。
- **P48**：対象GEOのKAPA HyperPrep記載は確認できましたが、VAHTSとの組合せは未確認。製品成分の記載だけから鎖特異性を決めていません。[資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5739830) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5739832) / [資料3](https://www.nature.com/articles/s41556-022-00846-7) / [資料4](https://bio.vazyme.com/product/332.html)

### 全49件の判定一覧

原記載・理由・照合したアクセッションの詳細は[監査TSV](rna_library_audit.tsv)にあります。複数アッセイを含む論文では対象RNA-seqに対応する証拠を使いました。GEOは各プロジェクトの代表的な熱側／対照側サンプルを独立取得し、元データ内の共通記載と照合しています。全Runの外部情報を1件ずつ再取得した監査ではありません。

| ID／行数 | 対象アクセッション | 修正版rna_library | 判定 | 証拠 |
| --- | --- | --- | --- | --- |
| P01／2 | GSE253874 | TruSeq Stranded Total RNA Library Prep Kit with Ribo-Zero Human/Mouse/Rat | 確認済み | [資料1](https://onlinelibrary.wiley.com/doi/full/10.1111/gtc.13140) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8029688) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8029686) |
| P02／3 | GSE235351 | unknown | 未解決 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7500881) / [資料2](https://pmc.ncbi.nlm.nih.gov/articles/PMC10439175/) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7500878) |
| P03／4 | GSE124609 | TruSeq RNA (product/version unspecified) | 部分的に支持 | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC7749315/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3537584) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3537582) |
| P04／36 | GSE115973 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3197024) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3197052) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3197068) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3197065) |
| P05／3 | GSE79680 | TruSeq RNA (product/version unspecified) | 部分的に支持 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2101093) / [資料2](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0152424) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2101090) |
| P06／3 | GSE267930 | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8281737) / [資料2](https://pubmed.ncbi.nlm.nih.gov/37905100/) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8281734) |
| P07／15 | GSE271918; GSE247417 | unknown | 修正 | [資料1](https://advanced.onlinelibrary.wiley.com/doi/10.1002/advs.202309588) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7889752) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE247417) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8389003) / [資料5](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8389000) / [資料6](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC11481226/supplementaryFiles) |
| P08／58 | GSE259306 | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | 修正 | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC12327812/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113675) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113720) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113661) / [資料5](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8113659) |
| P09／6 | GSE159802, GSE159803 | unknown | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4847384) / [資料2](https://elifesciences.org/articles/69843.pdf) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4847382) |
| P10／5 | GSE73471 | TruSeq RNA (product/version unspecified) | 部分的に支持 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1895369) / [資料2](https://pubmed.ncbi.nlm.nih.gov/27536004/) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1895367) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1895365) |
| P11／2 | GSE53667 | unknown | 修正 | [資料1](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0094968) / [資料2](https://pubmed.ncbi.nlm.nih.gov/24736721/) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1298381) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1298379) / [資料5](https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0094968.s001&type=supplementary) |
| P12／6 | GSE150922 | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4561044) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE150922) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC8269038/) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4561027) / [資料5](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4561021) / [資料6](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4561039) |
| P13／3 | GSE189578 | TruSeq RNA (product/version unspecified) | 不一致あり | [資料1](https://www.nature.com/articles/s41467-024-51258-0) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5704146) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5704143) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189578) |
| P14／3 | GSE227393 | VAHTS mRNA-seq v2 Library Prep Kit for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7134541) / [資料2](https://www.nature.com/articles/s41467-024-46358-w) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7099898) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7099897) |
| P15／12 | GSE228346 | KAPA mRNA HyperPrep Kit | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC11870056/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE228346) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7119261) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7119255) |
| P16／4 | GSE255207, GSE255208 | SMARTer Stranded Total RNA-Seq Kit v2 | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8065769) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8065773) / [資料3](https://pubmed.ncbi.nlm.nih.gov/39413186/) / [資料4](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8065765) / [資料5](https://pmc.ncbi.nlm.nih.gov/articles/PMC11482332/) |
| P17／3 | GSE270672 | QuantSeq 3′ mRNA-Seq Library Prep Kit FWD for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8349806) / [資料2](https://pmc.ncbi.nlm.nih.gov/articles/PMC11260097/) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8349803) |
| P18／6 | GSE197993, GSE197995 | KAPA mRNA HyperPrep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5935415) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5935414) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC9098121/) |
| P19／1 | GSE137559, GSE137560 | unknown | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4081765) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4081763) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC6826487/) |
| P20／1 | GSE130892 | unknown | 未解決 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3755850) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3755856) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC7170965/) |
| P21／9 | GSE132447 | TruSeq Stranded Total RNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3864915) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3864912) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC7802813/) |
| P22／6 | GSE289231 | unknown | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8787406) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8787400) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC11988828/) |
| P23／5 | GSE279569 | VAHTS Universal V6 RNA-seq Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8576137) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8576132) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC11876915/) |
| P24／52 | GSE285497 | NEBNext Ultra RNA Library Prep Kit for Illumina | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8703440) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8703439) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE285497) / [資料4](https://pubmed.ncbi.nlm.nih.gov/38484921/) / [資料5](https://pubmed.ncbi.nlm.nih.gov/41314531/) |
| P25／6 | GSE279445 | unknown | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8570762) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8570761) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC11609292/) |
| P26／3 | GSE229915 | TruSeq Stranded mRNA LT Sample Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7180386) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7180383) |
| P27／4 | GSE242710 | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7767455) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM7767451) |
| P28／4 | GSE221579 | NEBNext Ultra II Directional RNA Library Prep with Sample Purification Beads (E7765L) | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6886658) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6886642) |
| P29／6 | GSE164834 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5020469) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5020463) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC9237102/) |
| P30／12 | GSE182960 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5543754) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5543742) |
| P31／12 | GSE198441 | MSR-seq (custom mRNA library preparation) | 修正 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5946922) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5946919) / [資料3](https://pmc.ncbi.nlm.nih.gov/articles/PMC9072684/) |
| P32／3 | GSE164846 | KAPA Stranded mRNA-Seq Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5020921) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5020918) |
| P33／6 | GSE149797, GSE149799 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4512824) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4512821) |
| P34／4 | GSE123980 | Ovation Universal RNA-Seq System | 確認済み | [資料1](https://www.nature.com/articles/s41467-019-11536-8) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3518113) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3518111) |
| P35／1 | GSE115731 | TruSeq Stranded Total RNA Library Prep Kit (without rRNA depletion) | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC6249693/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3188431) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM3188430) |
| P36／6 | GSE100408 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2680462) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2680468) |
| P37／6 | GSE222110 | unknown | 不一致あり | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6914924) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM6914918) / [資料3](https://www.nature.com/articles/s41467-023-43262-7) |
| P38／3 | GSE124510 | KAPA RNA HyperPrep Kit | 確認済み | [資料1](https://www.nature.com/articles/s41467-020-15521-4) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4231707) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4231704) |
| P39／6 | GSE194098 | QuantSeq 3′ mRNA-Seq Library Prep Kit FWD for Illumina | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC8926329/) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5828056) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5828054) |
| P40／1 | GSE180253 | SMARTer Stranded Total RNA-Seq Kit v2 - Pico Input Mammalian (634413) | 修正 | [資料1](https://www.nature.com/articles/s41467-021-25105-5) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5456689) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5456703) |
| P41／16 | GSE145525 | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4871709) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4871707) / [資料3](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM4871721) / [資料4](https://pmc.ncbi.nlm.nih.gov/articles/PMC7849361/) |
| P42／4 | PRJDB12380; PRJDB9451 | TruSeq Stranded mRNA Library Prep Kit (without poly(A) selection) | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC9891252/) / [資料2](https://rnajournal.cshlp.org/content/29/2/170.full.pdf) |
| P43／23 | PRJDB13489; PRJDB3761 | SureSelect Strand-Specific RNA Library Preparation Kit | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC9113944/) |
| P44／3 | PRJEB5979 | Illumina protocol (specific kit unspecified) | 部分的に支持 | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC6707813/) / [資料2](https://www.ebi.ac.uk/gxa/experiments/E-MTAB-2349) |
| P45／4 | PRJEB44754 | TruSeq Stranded mRNA Library Prep Kit | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC10083568/) / [資料2](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10083568/supplementaryFiles) |
| P46／2 | PRJEB64703 | NEBNext Ultra II RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC12324416/) |
| P47／6 | PRJNA1169616 | TruSeq RNA (product/version unspecified) | 部分的に支持 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8557427) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8557425) |
| P48／2 | GSE191134 | KAPA HyperPrep Kit (KR0961); VAHTS RNA library component unverified | 部分的に支持 | [資料1](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5739830) / [資料2](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM5739832) / [資料3](https://www.nature.com/articles/s41556-022-00846-7) / [資料4](https://bio.vazyme.com/product/332.html) |
| P49／14 | PRJCA005446 | NEBNext Ultra Directional RNA Library Prep Kit for Illumina | 確認済み | [資料1](https://pmc.ncbi.nlm.nih.gov/articles/PMC9232687/) / [資料2](https://link.springer.com/article/10.1007/s13238-021-00887-y) / [資料3](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC9232687/supplementaryFiles) |

## 3. rna_library の表記統一案

原記載44種類（空欄・unknownを含む）を、表記のみの統一では30種類に整理しました。文献照合による訂正・補完後の修正版は26種類です。下表の「統一案」は表記だけの対応であり、誤転記の訂正を含む最終値は上の監査一覧を優先します。

大文字・小文字、商標記号、kit／Kit、TrueSeq／TruSeqを揃えました。Stranded／Directional、Ultra／Ultra II、mRNA／Total RNA、LT、FWD、rRNA除去やpoly(A)選択の省略は意味のある差として保持しました。

| 原記載 | 表記統一案 | 種類 | 行数 |
| --- | --- | --- | --- |
| TruSeq Stranded Total RNA Library Prep Kit | TruSeq Stranded Total RNA Library Prep Kit | library_preparation | 2 |
| unknown | unknown | missing | 4 |
| Illumina kit (TruSeq RNA) | TruSeq RNA (product/version unspecified) | library_preparation | 4 |
| Illumina TruSeq Stranded mRNA Sample Preparation Guide | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 36 |
| Truseq RNA prep kit | TruSeq RNA (product/version unspecified) | library_preparation | 3 |
| NEBNext Ultra II Directional RNA Library Prep Kit | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | library_preparation | 13 |
| Bioyi Biotechnology Co., Ltd. | Bioyi Biotechnology Co., Ltd. | service_provider | 73 |
| Direct-Zol RNA MiniPrep Kit | Direct-zol RNA MiniPrep Kit | extraction_or_cleanup | 6 |
| TrueSeq RNA Sample Preparation Kit | TruSeq RNA Sample Preparation Kit (version unspecified) | library_preparation | 5 |
| miRNeasy Kit | miRNeasy Kit | extraction_or_cleanup | 2 |
| TruSeq RNA Sample Preparation Kit | TruSeq RNA Sample Preparation Kit (version unspecified) | library_preparation | 3 |
| VAHTS mRNA-seq v2 Library Prep Kit for Illumina | VAHTS mRNA-seq v2 Library Prep Kit for Illumina | library_preparation | 3 |
| KAPA mRNA HyperPrep Kit | KAPA mRNA HyperPrep Kit | library_preparation | 12 |
| SMARTer Stranded Total RNA-Seq Kit v2 | SMARTer Stranded Total RNA-Seq Kit v2 | library_preparation | 4 |
| Lexogen QuantSeq FWD kit | QuantSeq 3′ mRNA-Seq Library Prep Kit FWD for Illumina | library_preparation | 3 |
| KAPA mRNA HyperPrep kit | KAPA mRNA HyperPrep Kit | library_preparation | 6 |
| Direct-ZolTM RNA MiniPrep Kit | Direct-zol RNA MiniPrep Kit | extraction_or_cleanup | 1 |
| TruSeq mRNA Library Prep Kit | TruSeq mRNA Library Prep Kit | library_preparation | 1 |
| TruSeq stranded total RNA protocol | TruSeq Stranded Total RNA Library Prep Kit | library_preparation | 9 |
| RNA Clean and Concentrator-25 kit | RNA Clean & Concentrator-25 Kit | extraction_or_cleanup | 6 |
| VAHTS Universal V6 RNA-seq Library Prep Kit | VAHTS Universal V6 RNA-seq Library Prep Kit | library_preparation | 5 |
| Qiagen RNeasy series kit | Qiagen RNeasy series kit | extraction_or_cleanup | 52 |
| RNA microprep kit | RNA microprep kit | extraction_or_cleanup | 6 |
| TruSeq Stranded mRNA LT Sample Prep Kit | TruSeq Stranded mRNA LT Sample Prep Kit | library_preparation | 3 |
| E7765L NEBNext Ultra II Directional RNA Library Prep with Beads | NEBNext Ultra II Directional RNA Library Prep with Sample Purification Beads (E7765L) | library_preparation | 4 |
| TruSeq Stranded mRNA Library Prep Kit | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 6 |
| TruSeq Stranded mRNA Library | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 12 |
| — | unknown | missing | 18 |
| KAPA Stranded mRNA-Seq Kit | KAPA Stranded mRNA-Seq Kit | library_preparation | 3 |
| TruSeq stranded mRNA library preparation kit | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 6 |
| Ovation Universal RNA-Seq System | Ovation Universal RNA-Seq System | library_preparation | 4 |
| TruSeq Total RNA kit | TruSeq Total RNA kit | library_preparation | 1 |
| TruSeq Stranded mRNA Library Kit | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 6 |
| TruSeq stranded mRNA library prep kit | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 6 |
| Hyper Prep RNA sequencing kit | Hyper Prep RNA sequencing kit (product unspecified) | library_preparation | 3 |
| Lexogen QuantSeq FWD Kit | QuantSeq 3′ mRNA-Seq Library Prep Kit FWD for Illumina | library_preparation | 6 |
| NEBNext Ultra II Directional RNA library preparation kit | NEBNext Ultra II Directional RNA Library Prep Kit for Illumina | library_preparation | 16 |
| TruSeq Stranded mRNA Library Prep Kit (without poly(A) selection) | TruSeq Stranded mRNA Library Prep Kit (without poly(A) selection) | library_preparation | 4 |
| SureSelect Strand-Specific RNA Library Preparation Kits | SureSelect Strand-Specific RNA Library Preparation Kit | library_preparation | 23 |
| Illumina protocol | Illumina protocol (specific kit unspecified) | library_preparation | 3 |
| TruSeq Stranded mRNA assay | TruSeq Stranded mRNA Library Prep Kit | library_preparation | 4 |
| NEBNext Ultra II RNA Library Prep Kit for Illumina | NEBNext Ultra II RNA Library Prep Kit for Illumina | library_preparation | 2 |
| AHTS universal V8 RNA-seq library prep kit for Illumina (Vazyme, cat. no. NR605) & KAPA HyperPrep kit (Roche, cat. no. KR0961) | VAHTS Universal V8 RNA-seq Library Prep Kit for Illumina (Vazyme, cat. no. NR605) & KAPA HyperPrep kit (Roche, cat. no. KR0961) | mixed_components | 2 |
| NEBNext® UltraTM Directional RNA Library Prep Kit | NEBNext Ultra Directional RNA Library Prep Kit for Illumina | library_preparation | 14 |

## 4. メーカー資料による鎖特異性の確認

以下は調査停止時点の結果です。「保持する設計」は実測での保証ではありません。`unknown`は`unstranded`と異なります。Read 1の向きは元RNAに対する方向であり、ゲノムの＋／−鎖そのものを意味しません。

| 根拠ID／製品 | 鎖情報の保持 | Read 1の向き | 資料・該当箇所 | 限界 |
| --- | --- | --- | --- | --- |
| M01／TruSeq Stranded Total RNA Library Prep Kit | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://sapac.support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-total-rna-workflow/truseq-stranded-total-rna-workflow-reference-1000000040499-00.pdf) / [資料2](https://knowledge.illumina.com/library-preparation/rna-library-prep/library-preparation-rna-library-prep-faq-list/000001233)<br>Reference Guide 1000000040499 v00: 本文p.2のstrand specificity、p.4のRead 1、p.5のRead 2（PDF pages 5,7,8）。Knowledge article #1233: Which strand is sequenced? | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。Ribo-Zeroの具体的variantが記録されていなければ補わない。 |
| M02／TruSeq Stranded Total RNA Library Prep Kit with Ribo-Zero Human/Mouse/Rat | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://emea.illumina.com/library-prep-array-kit-selector/kits-and-arrays/truseq-stranded-total-rna-ribo-zero-h-m-r.html) / [資料2](https://sapac.support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-total-rna-workflow/truseq-stranded-total-rna-workflow-reference-1000000040499-00.pdf)<br>H/M/R kit selector説明; Reference Guide 1000000040499 v00 本文pp.1,4–5（PDF pages 4,7–8） | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。旧H/M/R名称と現行構成の変更を名称差として認識し、Ribo-Zero Plusへ置換しない。 |
| M03／TruSeq Stranded Total RNA Library Prep Kit (without rRNA depletion) | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://sapac.support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-total-rna-workflow/truseq-stranded-total-rna-workflow-reference-1000000040499-00.pdf)<br>Reference Guide 1000000040499 v00: Process、本⽂pp.1–5 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。P35のrRNA除去省略は原研究の変更。ここでのR1方向は母体製品の方向性を記録し、変更後試料の実測値ではない。 |
| M04／TruSeq Stranded mRNA Library Prep Kit | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://www.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf) / [資料2](https://support.illumina.com/sequencing/sequencing_kits/truseq-stranded-mrna.html)<br>Reference Guide 1000000040498 v00: 本文pp.2–4（PDF pages 5–7）; Support Catalog IDs 20020594,20020595 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。P37ではGEOがこの製品を記す一方、論文はTruSeq RNA v2を記すため、この製品能力をP37の確定値にはしない。 |
| M05／TruSeq Stranded mRNA LT Sample Prep Kit | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://emea.illumina.com/library-prep-array-kit-selector/kits-and-arrays/truseq-stranded-mrna.html) / [資料2](https://www.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf)<br>Kit selector: LT/HT explanation; Reference Guide 1000000040498 v00: Final Library, Read 1/Read 2 本文pp.3–4 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。LTを非stranded TruSeq RNA v2と混同しない。 |
| M06／TruSeq Stranded mRNA Library Prep Kit (without poly(A) selection) | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://www.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf)<br>Reference Guide 1000000040498 v00: Process、Synthesize Second Strand cDNA、Read 1/Read 2 本文pp.1–4 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。P42は標準のpoly(A)選択を省略。製品の方向性からの期待値であり、変更後の試料についてFASTQ検証した値ではない。 |
| M07／TruSeq RNA Library Prep Kit v2 | 保持しない設計 | 未確認 | [資料1](https://www.illumina.com/products/by-type/sequencing-kits/library-prep-kits/truseq-rna-v2.html)<br>Product Specifications: Strand specificity / Content specifications | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。データ内ではP37の論文側候補。GEO側のTruSeq Stranded mRNAと矛盾するので、P37をunstrandedへ確定変更してはいけない。版を欠くTruSeq RNA記載にも適用しない。 |
| M08／TruSeq RNA / TruSeq RNA Sample Preparation (product/version unspecified) | 未確定 | 未確認 | [資料1](https://www.illumina.com/products/by-type/sequencing-kits/library-prep-kits/truseq-rna-v2.html) / [資料2](https://www.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf) / [資料3](https://sapac.support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-total-rna-workflow/truseq-stranded-total-rna-workflow-reference-1000000040499-00.pdf)<br>TruSeq RNA v2仕様; Stranded mRNA/Total RNA Reference Guide | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。名称中にStrandedがないことだけを根拠にv2やnon-strandedと確定しない。P13にはDOI不整合も残る。P20の元TruSeq mRNAは対象試料への適用未確認なので本配列の確定対応から除外。 |
| M09／NEBNext Ultra RNA Library Prep Kit for Illumina (E7530) | 保持しない設計 | 未確認 | [資料1](https://www.neb.com/en-gb/products/e7530-nebnext-ultra-rna-library-prep-kit-for-illumina) / [資料2](https://www.neb.com/en/-/media/nebus/files/manuals/manuale7530.pdf?hash=DB47CB277C42E13EA3AA9492F7FFC585&rev=071d46347b5c4d1aa116f27abd8f1d22)<br>Product Information; E7530 manual Section 6 FAQ, 本文p.30 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。P24の登録情報が省略せず製品名を記録しているという前提。Ultra IIやDirectionalへ改称しない。 |
| M10／NEBNext Ultra II RNA Library Prep Kit for Illumina (E7770) | 保持しない設計 | 未確認 | [資料1](https://www.neb.com/en/products/e7770-nebnext-ultra-ii-rna-library-prep-kit-for-illumina) / [資料2](https://www.neb.com/en-us/faqs/2017/07/17/what-is-the-difference-between-the-nebnext-ultra-ii-rna-library-prep-with-sample-purification-bea)<br>Product overview; E7775/E7765比較FAQの回答 | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。単にUltra IIが含まれるだけでDirectionalと判定しない。P46は製品名どおりの標準版を用いた場合の能力。 |
| M11／NEBNext Ultra Directional RNA Library Prep Kit for Illumina (E7420) | 保持する設計 | 未確認 | [資料1](https://www.neb.com/en/products/e7420-nebnext-ultra-directional-rna-library-prep-kit-for-illumina)<br>Product Information; Features: Accurate retention of transcript strand of origin information / Utilizes dUTP-based methodology | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。今回確認したメーカー公式製品ページ・マニュアルはdUTP方式とstrand保持を明記するが、RNAに対するR1のsense/antisense対応を明示する箇所は確認できず、R1はunknownとした。dUTP方式という一般論だけから解析設定を確定しない。旧版E7420を後継Ultra II E7760へ名称変更しない。 |
| M12／NEBNext Ultra II Directional RNA Library Prep Kit for Illumina (E7760) | 保持する設計 | 未確認 | [資料1](https://www.neb.com/en/products/e7760-nebnext-ultra-ii-directional-rna-library-prep-kit-for-illumina) / [資料2](https://www.neb.com/en-au/-/media/nebus/files/manuals/manuale7760_e7765.pdf?hash=514FCB2B6350D58C906ED16F8C19135E&rev=a5a99045a0bf4ee8afaf80fd2e3653dc)<br>E7760 Product Information; E7760/E7765 manual introductionおよびkit components | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。今回確認したメーカー公式製品ページ・マニュアルはdUTP方式とstrand保持を明記するが、RNAに対するR1のsense/antisense対応を明示する箇所は確認できず、R1はunknownとした。dUTP方式という一般論だけから解析設定を確定しない。 |
| M13／NEBNext Ultra II Directional RNA Library Prep with Sample Purification Beads (E7765) | 保持する設計 | 未確認 | [資料1](https://www.neb.com/products/e7765-nebnext-ultra-ii-directional-rna-library-prep-with-sample-purification-beads) / [資料2](https://www.neb.com/en-us/faqs/2017/07/17/what-is-the-difference-between-the-nebnext-ultra-ii-rna-library-prep-with-sample-purification-bea) / [資料3](https://www.neb.com/en-au/-/media/nebus/files/manuals/manuale7760_e7765.pdf?hash=514FCB2B6350D58C906ED16F8C19135E&rev=a5a99045a0bf4ee8afaf80fd2e3653dc)<br>E7765 Product Information; E7775/E7765比較FAQ; shared E7760/E7765 manual | 製品の標準ワークフローとしての能力であり、各登録試料が実際にその手順で作製されたことや観測されたstrandnessを保証しない。今回確認したメーカー公式製品ページ・マニュアルはdUTP方式とstrand保持を明記するが、RNAに対するR1のsense/antisense対応を明示する箇所は確認できず、R1はunknownとした。dUTP方式という一般論だけから解析設定を確定しない。ビーズ同梱の有無によるstrandnessの違いではない。 |
| M14／KAPA mRNA HyperPrep Kit | 保持する設計 | 未確認 | [資料1](https://rochesequencingstore.com/wp-content/uploads/2017/10/KAPA-mRNA-HyperPrep-Kit-Illumina-1.pdf) / [資料2](https://rochesequencingstore.com/catalog/kapa-mrna-hyperprep-kit/?attribute_options=96rxn)<br>KR1352 v4.17 (January 2017), p.1 Quick Notes / p.2 Product Description; Roche product Description | 標準ワークフローの製品能力であり実測したstrandnessではない。R1/R2の方向はこの一次メーカー資料では明示を確認できないためunknown。現在のRoche RNAページが後継EvoPrep製品へ変わっているため、旧HyperPrepのTechnical Data Sheetを使用。 |
| M15／KAPA RNA HyperPrep Kit | 保持する設計 | 未確認 | [資料1](https://rochesequencingstore.com/catalog/kapa-rna-hyperprep-kit/) / [資料2](https://rochesequencingstore.com/wp-content/uploads/2023/01/MC-01922-External-KAPA-RNA-HyperPrep-Brochure.pdf)<br>製品ページ Description; KAPA RNA HyperPrep brochure p.2 Key Features | KAPA HyperPrep DNAキットとは別製品。対象論文の時間経過実験に使われたRiboEraseオプションをP38対象3行へ一律追加しない。R1/R2方向のメーカー明示は今回確認できずunknown。 |
| M16／KAPA Stranded mRNA-Seq Kit | 保持する設計 | 未確認 | [資料1](https://rochesequencingstore.com/wp-content/uploads/2022/07/KAPA-Stranded-mRNA-Seq-Kit-Technical-Data-Sheet.pdf)<br>Technical Data Sheet p.2 Product Description | KAPA mRNA HyperPrepとは製品を区別する。R1のsense/antisenseをこのメーカー資料では明示確認できずunknownとした。 |
| M17／KAPA HyperPrep Kit (DNA library preparation; KR0961) | 未確定 | 未確認 | [資料1](https://rochesequencingstore.com/wp-content/uploads/2017/10/07962363001_KAPA-HyperPrep-Kit-PCR-free-v7.19.pdf)<br>KR0961 v7.19 (August 2019), p.1 Quick Notes / p.2 Product Description | KR0961はマニュアル番号であり注文用catalog番号そのものではない。DNA用キットを使ったcDNA処理はあり得るので、RNA-seqへの使用を誤りと断定したり、直ちにunstrandedと分類しない。P48ではRNA/cDNA作製工程とVAHTSの組合せ未確認のため最終strandnessはunknown。 |
| M18／VAHTS mRNA-seq v2 Library Prep Kit for Illumina (NR601) | 未確定 | 未確認 | [資料1](https://www.interchim.fr/ft/B/B0EJM0.pdf) / [資料2](https://bio.vazyme.com/product/194.html)<br>Vazyme Instruction Manual,表紙でNR601を確認; PDF p.3 Contents / p.3–4 Introduction / p.5–6 double-strand cDNA synthesis / p.11 Library Amplification; Vazyme公式RNA Adapters製品説明 | 標準マニュアルからunstrandedの可能性を推定できるが、メーカーによる明示的な判定を未確認のため、途中結果ではunknownを採用。unstrandedはメーカーの明示文ではなく、メーカー作成の標準マニュアルに基づく推定。NR601マニュアルはメーカー外の販売代理店Interchim所蔵コピーを利用（TogoMCP外）。論文で独自にdirectional処理を加えた場合はこの推定を適用できない。実試料での検証は未実施。 |
| M19／VAHTS Universal V6 RNA-seq Library Prep Kit for Illumina (NR604) | 方式の選択による | 未確認 | [資料1](https://www.lifesct.com/download/Manuals/NR604-VAHTS-Universal-V6-RNA-seq-Library-Prep-Kit.pdf) / [資料2](https://www.cellagentech.com/content/product_files/Vazyme/NR604_VAHTS_Universal_V6_RNA-seq_Library_Prep_Kit.pdf)<br>NR604-01/02 Version 9.1, p.1 01/Introduction and 02/Components | Vazyme作成マニュアルのメーカー外販売代理店所蔵コピーを利用（TogoMCP外）。P23では選択モードが明示されていないため実試料strandness unknown。R1方向もモード未確定のためunknown。 |
| M20／VAHTS Universal V8 RNA-seq Library Prep Kit for Illumina (NR605) | 方式の選択による | 未確認 | [資料1](https://bio.vazyme.com/product/332.html) / [資料2](https://www.stratech.co.uk/wp-content/uploads/2020/02/2020-Vazyme-Brochure-for-NGS-Lib-Prep-v200124.pdf)<br>Vazyme公式 Product Description「试剂盒包含两种类型的cDNA二链合成Buffer…」; Vazyme 2020 Product Catalogue p.13 RNA-Seq Library Preparation | V8 (NR605)とV6 (NR604)を混同しない。P48で本キットが実際にどのRNA-seq工程に使われたかは未確認であり、方向性モードも未確定。2020メーカー発行カタログはStratech販売代理店所蔵コピー（TogoMCP外）を使用。製品能力conditionalからP48をstrandedへ補完しない。 |
| M21／Ovation Universal RNA-Seq System (NuGEN; Part No. 0343) | 保持する設計 | 未確認 | [資料1](https://manualzz.com/doc/7459214/nugen-ovation-universal-rna-seq-system-user-guide) / [資料2](https://www.tecan.com/campaigns/tecan-and-nugen-bringing-genomics-solutions-to-you)<br>NuGEN ©2014 User Guide, Part No.0343, p.1 Introduction / p.34 Appendix FAQ Q9; TecanのNuGEN統合案内 | 旧NuGENマニュアルの第三者ミラーManualzzを利用（TogoMCP外）。Tecan公式にある後継Universal RNA-Seq with NuQuantは別名称なので、そのforward-read sense記述を旧Ovation製品へ無条件に転用しない。旧ガイドのantisense insert記述をR1の向きと混同せずR1はunknown。P34の論文自体にもstrand-specificとの記載あり。 |
| M22／QuantSeq 3′ mRNA-Seq Library Prep Kit FWD for Illumina | 保持する設計 | 元RNAと同方向 | [資料1](https://www.lexogen.com/quantseq-3mRNA%20sequencing/)<br>製品説明、Workflow | FWDをREVに統合しない。3′末端・poly(A) RNA中心の測定であり全長total RNAと対象が異なる。 |
| M23／SMARTer Stranded Total RNA-Seq Kit v2 - Pico Input Mammalian | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://catalog.takara-bio.co.jp/product/basic_info.php?catcd=B1000879&subcatcd=B1001121&unitid=U100009274)<br>製品説明、図2の説明 | P40は634413まで一致。P16はv2の名称を確認したが詳細なcatalog番号は未記載。旧v1やSMART-Seqシリーズと混同しない。 |
| M24／SureSelect Strand-Specific RNA Library Preparation Kit | 保持する設計 | 元RNAの逆相補方向 | [資料1](https://www.agilent.com/cs/library/usermanuals/public/G9691-90010.pdf) / [資料2](https://www.agilent.com/en/product/next-generation-sequencing/ngs-library-prep-target-enrichment-reagents/rna-seq-reagents/sureselect-strand-specific-rna-library-preparation-for-whole-transcriptome-sequencing-4252224)<br>Protocol version F0 (June 2020), 印刷p.44 Sequence analysis guidelines | 対象はStrand-Specific RNA製品。SureSelect一般のDNA capture製品にこの判定を広げない。 |
| M25／MSR-seq (custom mRNA library preparation) | 未確定 | 未確認 | [資料1](https://www.nature.com/articles/s41467-022-30261-3)<br>Fig.1、Methods mRNA library construction | メーカー資料なし。custom protocolとして保持。NEBNext Poly(A)選択モジュール単体からstrandednessを決めない。 |
| M26／Direct-zol RNA MiniPrep Kit | 対象外（抽出・精製） | 対象外 | [資料1](https://www.zymoresearch.com/products/direct-zol-rna-miniprep-kits)<br>Product description | not_applicableはnon-strandedを意味しない。後続の作製法が必要。 |
| M27／miRNeasy Kit / RNeasy series | 対象外（抽出・精製） | 対象外 | [資料1](https://www.qiagen.com/be/products/discovery-and-translational-research/dna-rna-purification/rna-purification/mirna/mirneasy-kits) / [資料2](https://www.qiagen.com/gf/product-categories/discovery-and-translational-research/dna-rna-purification/rna-purification/total-rna)<br>Product Details / Total RNA製品一覧 | P24の実際のライブラリー製品はNEBNext Ultra（文献・GEO照合で修正）。 |
| M28／RNA Clean & Concentrator-25 Kit | 対象外（抽出・精製） | 対象外 | [資料1](https://www.zymoresearch.com/products/rna-clean-concentrator-25)<br>Product description | メーカー名・受託先が同じでも後続キットを推定しない。 |
| M29／Quick-RNA Microprep Kit (R1050) | 対象外（抽出・精製） | 対象外 | [資料1](https://files.zymoresearch.com/literature/pdf/b1003_rna_brochure.pdf)<br>Quick-RNA Microprepの製品表 | マニュアルでのRNA保存・回収とライブラリー鎖情報の保持は別。 |
| M30／Bioyi / Illumina protocol / unknown | 未確定 | 未確認 | 具体的製品を特定できず<br>該当する製品の一次仕様を特定できず | unstrandedと分類しない。 |

**VAHTS V6／V8は作製方式の選択によって結果が変わるため、製品名だけではstrandedと確定できません。** VAHTS v2 NR601は非鎖特異的である可能性を資料から推定できますが、明示的な裏付けの追加確認を停止したため修正版ではunknownとしました。

NEBNextのDirectional製品は鎖情報保持を確認しましたが、今回取得済みのメーカー資料でRead 1方向の明示までは確認できず、向きはunknownです。KAPA RNA系・Ovationも、Read 1方向は未確認のまま残しました。市販製品に対応しないMSR-seqは独自法として記録し、解析方向を断定していません。

修正版の鎖判定は次のとおりです。全て文献・登録情報・製品設計からの期待値で、実測値ではありません。

| strandedness_assessment | 比較行数 |
| --- | --- |
| expected_stranded | 259 |
| unknown | 81 |
| protocol_dependent | 5 |
| expected_unstranded | 54 |
| conflicting | 6 |

## 修正版TSVの読み方と検証

| 追加列 | 意味 |
| --- | --- |
| audit_record_id | 元行に対応するR0001〜R0405 |
| library_audit_id | 本レポート・監査TSVのP01〜P49 |
| rna_library_original | 修正前の文字列をそのまま保存 |
| rna_library_audit_status | 確認済み・修正・部分支持・未解決・不一致の機械可読ラベル |
| rna_extraction_kit | 確認できた抽出・精製キット |
| library_service_provider | 裏付けられた委託先。会社名をキット名と分離 |
| kit_strand_capability | 製品設計から分かる鎖特異性。未確認はunknown |
| strandedness_assessment | 対象試料に対する文献ベースの期待判定 |
| expected_read1_orientation | sense／antisense／unknown |
| strand_evidence_ids | 上のメーカー資料表のM番号 |
| reference_doi_audit_status | DOI対応の支持・未確認・不一致 |
| reference_doi_suggested | 根拠を得た代替候補。元DOIを自動置換しない |
| metadata_audit_flags | 原メタデータの追加要確認事項 |

熱側・対照側Run ID、行数、行順、ペアの対応を維持しました。安全な19組の統合で値の実質的な競合は0件でした。統合元の全値を履歴TSVに保存し、修正版・履歴・rna_library_originalから元177列の全セルを復元できることを照合しました。条件付きカラムと未確認値は推測で埋めていません。

元データに残る要確認事項として、ヒトデータに`genome_build=mm9`が6行、RNA-seqに`library_source=GENOMIC`が12行あります。今回のキット監査だけでは修正できないため、原値を保持してフラグを追加しました。元から推測表現を含む対照温度も確定値に変換していません。

TSVはUTF-8、タブ区切り、引用符付きセルに対応する形式です。元メタデータ中の改行・タブ・引用符を保持するため、単純な行分割ではなくTSV対応のリーダーで読み込んでください。

## 使用リソースと未完了範囲

**TogoMCP**：`get_mie_file`、`get_sparql_endpoints`、`run_sparql`を使い、PubMed RDFをDOIで照会しました。提供された`ncbi_ncbi_esearch`はUnknown toolエラーとなり、同じプラグイン内のRDF照会に切り替えました。P27とP46はRDF検索で一致なしでした。

**TogoMCP以外**：NCBI GEOのSample／Series SOFT、PubMed・PMC、NCBI PMC ID Converter、Europe PMCの本文XML・補足資料取得、各出版社の論文・補足資料、Web検索、メーカー公式サイトを使用しました。GEO Sample 89件・Series 49件を取得しました。本文XMLは取得を試みた48書誌レコード中38件で成功し、他は出版社・GEO等で補いました。この件数は文献を確認できた件数と同一ではありません。

メーカー資料のうち、VAHTS旧製品マニュアルは販売代理店所蔵、旧OvationマニュアルはManualzzのミラーを含みます。メーカー著作の資料とメーカー公式サイトへの直接アクセスを区別し、上の個別リンクと注意欄に示しました。実験の再現・最適化手順は本レポートの対象にしていません。

**調査停止時点で残した事項**：P13の代替DOI、P07一部アクセッションのDOI・委託先対応、P37の製品矛盾、P48の製品組合せ、未特定キット、選択式キットの実使用モード、未確認のRead 1方向、実リードによる鎖特異性の検証。追加調査は停止しています。

入力ファイル：`rna_seq_all_metadata_260626.tsv`  <br>SHA-256：`580bdeaa36f38977604f025c1a3345a8c603730dc0ddae02683da39f48bbd278`
