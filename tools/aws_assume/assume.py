import os
from argparse import ArgumentParser
from copy import copy

import boto3


def cli():
	parser = ArgumentParser()
	parser.add_argument("--region", help="for which region to generate the credentials")
	parser.add_argument(
		"--role-name", help="which role to assume", default="GitlabAssumedRole"
	)
	parser.add_argument(
		"--session-name", help="name fot the created session", default="deployment"
	)
	parser.add_argument("target_account_id", help="target account ID to use")
	parser.add_argument("command", nargs="+", help="command to run")
	args = parser.parse_args()

	role_arn = f"arn:aws:iam::{args.target_account_id}:role/{args.role_name}"
	sts = boto3.client("sts", region_name=args.region)
	response = sts.assume_role(RoleArn=role_arn, RoleSessionName=args.session_name)

	env = copy(os.environ)
	env.update(
		{
			"AWS_ACCESS_KEY_ID": response["Credentials"]["AccessKeyId"],
			"AWS_SECRET_ACCESS_KEY": response["Credentials"]["SecretAccessKey"],
			"AWS_SESSION_TOKEN": response["Credentials"]["SessionToken"],
		}
	)
	if args.region:
		env["AWS_DEFAULT_REGION"] = args.region

	os.execvpe(args.command[0], args.command, env)
