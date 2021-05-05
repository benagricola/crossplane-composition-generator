/*
 * Generate a new Composite Resource Definition and
 * default Composition that implements this XRD.
 */
local k8s = import 'functions.libjsonnet';

// State
local s = {
  config: std.parseJson(std.extVar('config')),
  crd: std.parseJson(std.extVar('crd')),
  data: std.parseJson(std.extVar('data')),
};

local plural = k8s.NameToPlural(s.config.name);
local fqdn = k8s.FQDN(plural, s.config.group);
local resourceFqdn = k8s.FQDN(s.crd.names.kind, s.crd.group);
local version = k8s.GetVersion(s.crd, s.config.version);

local uidFieldPath = k8s.GetUIDFieldPath(s.config);
local uidFieldName = 'uid';

local definitionSpec = k8s.GenerateSchema(
  version.schema.openAPIV3Schema.properties.spec,
  s.config,
  ['spec'],
);

local definitionStatus = k8s.GenerateSchema(
  version.schema.openAPIV3Schema.properties.status,
  s.config,
  ['status'],
);


{
  definition: {
    apiVersion: 'apiextensions.crossplane.io/v1',
    kind: 'CompositeResourceDefinition',
    metadata: {
      name: fqdn,
    },
    spec: {
      group: s.config.group,
      names: {
        kind: s.config.name,
        plural: plural,
        categories: k8s.GenerateCategories(s.config.group),
      },
      versions: [
        {
          name: version.name,
          referenceable: version.storage,
          served: version.served,
          schema: {
            openAPIV3Schema: {
              properties: {
                spec: definitionSpec,
                status:
                  definitionStatus
                  // Add a UID property to every resource type. This will be
                  // patched from the crossplane external name so the UID
                  // can be propagated back to higher level constructs.
                  {
                    properties+: {
                      [uidFieldName]: {
                        description: 'The unique ID of this %s resource reported by the provider' % [s.config.name],
                        type: 'string',
                      },
                    },
                  },
              },
            },
          },
          additionalPrinterColumns: k8s.FilterPrinterColumns(version.additionalPrinterColumns),
        },
      ],
      defaultCompositionRef: {
        name: k8s.GetDefaultComposition(s.config.compositions),
      },
    },
  },
} + {
  ['composition-' + composition.name]: {
    apiVersion: 'apiextensions.crossplane.io/v1',
    kind: 'Composition',
    metadata: {
      name: composition.name,
      labels: k8s.GenerateLabels(s.config.purpose, composition.provider),
    },
    spec: {
      local spec = self,
      compositeTypeRef: {
        apiVersion: s.config.group + '/' + s.config.version,
        kind: s.config.name,
      },
      patchSets: [
        {
          name: 'Common',
          patches: k8s.GenOptionalPatchFrom(
            // Patch crossplane well-known metadata fields
            k8s.GenGlobalLabel([
              'claim-name',
              'claim-namespace',
              'composite',
            ])
            +
            // Patch company-specific fields
            k8s.GenPackageLabel([
              'purpose',
              'provider',
              'location',
              'identifier',
              'environment',
            ])
          ),
        },
        {
          name: 'Parameters',
          patches: k8s.GenOptionalPatchFrom(
            k8s.GeneratePatchPaths(
              definitionSpec.properties,
              s.config,
              ['spec']
            )
          ),
        },
        {
          name: 'Status',
          patches: k8s.GenOptionalPatchTo(
            k8s.GeneratePatchPaths(
              definitionStatus.properties,
              s.config,
              ['status']
            )
          ) + k8s.GenPatch(
            'ToCompositeFieldPath',
            uidFieldPath,
            'status.%s' % [uidFieldName],
            'fromFieldPath',
            'toFieldPath',
            'Optional'
          ),
        },
      ],
      resources: [
        {
          local resource = self,
          name: s.crd.spec.names.kind,
          base: {
            apiVersion: s.crd.spec.group + '/' + s.config.version,
            kind: resource.name,
            spec: {
              providerConfigRef: {
                name: 'default',
              },
            },
          } + k8s.SetDefaults(s.config),
          patches: [
            {
              type: 'PatchSet',
              patchSetName: ps.name,
            }
            for ps in spec.patchSets
          ],
        },
      ],
    },
  }
  for composition in s.config.compositions
}
