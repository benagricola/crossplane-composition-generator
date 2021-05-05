# Crossplane Composition Generator

A small project combining golang with jsonnet to autogenerate wrapper Compositions around underlying provider resources.

## Usage
This tool should not be used directly, but as a component of a `go:generate pipeline`.

In your target Crossplane Composite Resources repository, create a `generate.go` file at the root of the project, containing:

```go
// +build generate

package <package_name>

/*
// NOTE: See the below link for details on what is happening here.
// https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module

// Generate Composite Resources
//go:generate go run -tags generate github.com/benagricola/crossplane-composition-generator
*/
```

Once this file is created, you should be able to run `go generate` in your repository to generate new XRD outputs:

```bash
➜  crossplane-resources git: ✗ go generate
go: finding module for package github.com/benagricola/crossplane-composition-generator
go: found github.com/benagricola/crossplane-composition-generator in github.com/benagricola/crossplane-composition-generator.git v0.0.0-20210421140705-f755a8cb7a39
2021/04/21 15:21:51 Retrieving CRD file from ../provider-cloudflare/package/crds/sslsaas.cloudflare.crossplane.io_fallbackorigins.yaml
2021/04/21 15:21:51 Retrieving CRD file from ../provider-cloudflare/package/crds/dns.cloudflare.crossplane.io_records.yaml
2021/04/21 15:21:51 Retrieving CRD file from ../provider-cloudflare/package/crds/sslsaas.cloudflare.crossplane.io_fallbackorigins.yaml
2021/04/21 15:21:52 Retrieving CRD file from ../provider-cloudflare/package/crds/firewall.cloudflare.crossplane.io_filters.yaml
2021/04/21 15:21:52 Retrieving CRD file from ../provider-cloudflare/package/crds/firewall.cloudflare.crossplane.io_rules.yaml
2021/04/21 15:21:52 Retrieving CRD file from ../provider-cloudflare/package/crds/zone.cloudflare.crossplane.io_zones.yaml
```