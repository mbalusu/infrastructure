resource "aws_route53_zone" "public_zone" {
  name = "${var.route53_zone_public}"
}

resource "aws_route53_zone" "private_zone" {
  name = "${var.route53_zone_private}"
  vpc_id = "${aws_vpc.default.id}"
}
