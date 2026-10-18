# CPU上でTransfomerが利用できるDockerイメージを構築
# Download DNABERT_2_helper repository in current directory
git clone https://github.com/KazukiNakamae/DNABERT_2_helper.git;
# Build Docker image
sudo docker buildx build --platform linux/amd64 \
  --build-arg ENABLE_CUDA=0 \
  -t kazukinakamae/dnabert-eval:amd64 \
  DNABERT_2_helper;
# create cache directory for Huggingface Transformers
mkdir -p .hf_cache;

# モデルのリポジトリに自動アクセスしてmammal_ncRNA_promoter_test.csvを評価
docker run --platform=linux/amd64 --rm \
-v `pwd`:/DATA -w /DATA \
-v `pwd`/.hf_cache:/root/.cache/huggingface \
-i kazukinakamae/dnabert-eval:amd64 \
python DNABERT_2_helper/predict_hf_classifier_csv.py \
  --model_dir KazukiNakamae/mnpc \
  --input_file DNABERT_2_helper/testdata/mammal_ncRNA_promoter_test.csv \
  --output_file mntest.csv \
  --text_column sequence \
  --max_length 175 \
  --batch_size 32 \
  --trust_remote_code;