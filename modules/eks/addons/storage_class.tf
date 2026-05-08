resource "kubectl_manifest" "gp3_storage_class" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: gp3
      annotations:
        storageclass.kubernetes.io/is-default-class: "false"
    provisioner: ebs.csi.aws.com
    parameters:
      type: gp3
      encrypted: "true"
      kmsKeyId: ${var.kms_key_arn}
    reclaimPolicy: Delete
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
  YAML

  depends_on = [aws_eks_addon.ebs_csi_driver]
}
