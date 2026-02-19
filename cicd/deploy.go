package main

import (
	"context"

	"dagger/shorturl/internal/dagger"
)

// Deploy applies the OpenTofu/Terraform configuration to deploy the infrastructure
func (m *Shorturl) Deploy(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// +optional
	// Build artifact from the Build function to deploy
	buildArtifact *dagger.File,
	// AWS credentials
	awsAccessKeyId *dagger.Secret,
	awsSecretAccessKey *dagger.Secret,
	// +optional
	// AWS region (default: us-east-1)
	awsRegion string,
	// +optional
	// Environment name (default: dev)
	environment string,
) (string, error) {
	// Set defaults
	if awsRegion == "" {
		awsRegion = "us-east-1"
	}
	if environment == "" {
		environment = "dev"
	}

	// Create OpenTofu container
	tofuContainer := dag.Container().
		From("ghcr.io/opentofu/opentofu:latest").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace/terraform").
		WithSecretVariable("AWS_ACCESS_KEY_ID", awsAccessKeyId).
		WithSecretVariable("AWS_SECRET_ACCESS_KEY", awsSecretAccessKey).
		WithEnvVariable("AWS_REGION", awsRegion).
		WithEnvVariable("TF_VAR_aws_region", awsRegion).
		WithEnvVariable("TF_VAR_environment", environment)

	// If build artifact is provided, extract it to the terraform directory
	if buildArtifact != nil {
		println("Extracting build artifact...")
		tofuContainer = tofuContainer.
			WithFile("/workspace/terraform/lambda-deployment.tar.gz", buildArtifact).
			WithExec([]string{"sh", "-c", "mkdir -p /workspace/terraform/lambda && tar -xzf /workspace/terraform/lambda-deployment.tar.gz -C /workspace/terraform/ && rm /workspace/terraform/lambda-deployment.tar.gz"})
	}

	// Initialize OpenTofu
	println("Initializing OpenTofu...")
	tofuContainer = tofuContainer.
		WithExec([]string{"tofu", "init"})

	// Plan the deployment
	println("Planning OpenTofu deployment...")
	planOutput, err := tofuContainer.
		WithExec([]string{"tofu", "plan", "-out=tfplan"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}
	println(planOutput)

	// Apply the deployment
	println("Applying OpenTofu configuration...")
	applyOutput, err := tofuContainer.
		WithExec([]string{"tofu", "apply", "-auto-approve", "tfplan"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	// Get outputs
	println("Retrieving deployment outputs...")
	outputsJson, err := tofuContainer.
		WithExec([]string{"tofu", "output", "-json"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return applyOutput + "\n\nOutputs:\n" + outputsJson, nil
}
