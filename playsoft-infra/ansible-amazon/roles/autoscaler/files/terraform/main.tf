# Autoscaler-managed workers ONLY. The floor worker lives in the main
# aws_terrafrom state, not here -- this state starts empty (var.workers
# defaults to {}) and only ever contains what webhook.py's discovery-driven
# scale_out()/scale_in() put there. That separation is what makes "scale-in
# can never remove the floor" a structural guarantee instead of app logic
# that has to get it right. See ansible-amazon/roles/autoscaler/README.md.
resource "aws_instance" "worker" {
  for_each = var.workers

  ami           = var.ami_id
  instance_type = var.worker_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  subnet_id               = var.private_subnet_id
  private_ip              = each.value
  vpc_security_group_ids  = [var.worker_security_group_id]

  root_block_device {
    volume_size           = var.worker_root_volume_size
    volume_type            = "gp3"
    delete_on_termination = true
  }

  # Same userdata script as the floor worker (aws_terrafrom/modules/k8s-worker/
  # userdata/worker.sh) -- roles/autoscaler's tasks copy it here verbatim at
  # deploy time so there's exactly one source of truth for what a worker's
  # first boot does, not two scripts that can drift apart.
  user_data = base64encode(templatefile("${path.module}/userdata/worker.sh", {
    master_endpoint = var.master_endpoint
    region          = var.region
    cluster_name    = var.cluster_name
  }))

  tags = {
    Name               = each.key
    k8s_role           = "worker"
    kubernetes_cluster = var.cluster_name
    created_by         = "jilani"
  }
}

resource "aws_lb_target_group_attachment" "worker" {
  for_each = var.workers

  target_group_arn = var.target_group_arn
  target_id        = aws_instance.worker[each.key].id
  port              = var.app_nodeport
}
