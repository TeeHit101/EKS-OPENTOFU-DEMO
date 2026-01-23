cd bootstrap
tofu init
tofu fmt --recursive
tofu plan
tofu apply -auto-approve
cd ../envs/dev
tofu init
tofu fmt --recursive
tofu plan
tofu apply -auto-approve
