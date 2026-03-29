import { createRequire } from "node:module";
import type { ErrorObject, ValidateFunction } from "ajv";
import { loadJsonSchema } from "./schema-load.js";
import { specPaths } from "./paths.js";

const require = createRequire(import.meta.url);

type AjvInstance = {
  compile: (schema: object) => ValidateFunction;
};

type AjvConstructor = new (opts?: {
  allErrors?: boolean;
  strict?: boolean;
  allowUnionTypes?: boolean;
}) => AjvInstance;

const AjvModule: { default: AjvConstructor } = require("ajv/dist/2020.js") as {
  default: AjvConstructor;
};
const addFormats: (ajv: AjvInstance) => AjvInstance = require("ajv-formats") as (
  ajv: AjvInstance,
) => AjvInstance;

const ajv: AjvInstance = new AjvModule.default({
  allErrors: true,
  strict: true,
  allowUnionTypes: true,
});
addFormats(ajv);

const envelopeSchema: object = loadJsonSchema(specPaths.ingestionEnvelopeSchema);
const healthkitPayloadSchema: object = loadJsonSchema(specPaths.healthkitPayloadSchema);
const mockPayloadSchema: object = loadJsonSchema(specPaths.mockPayloadSchema);
const glucoseReadingSchema: object = loadJsonSchema(specPaths.glucoseReadingOgisSchema);

export const validateEnvelope: ValidateFunction = ajv.compile(envelopeSchema);
export const validateHealthkitPayload: ValidateFunction = ajv.compile(healthkitPayloadSchema);
export const validateMockPayload: ValidateFunction = ajv.compile(mockPayloadSchema);
export const validateGlucoseReadingOgis: ValidateFunction = ajv.compile(glucoseReadingSchema);

export function formatAjvErrors(errors: ErrorObject[] | null | undefined): string {
  if (errors === undefined || errors === null || errors.length === 0) {
    return "Validation failed";
  }
  return errors
    .map((e: ErrorObject) => {
      const path: string = e.instancePath === "" ? "/" : e.instancePath;
      return `${path}: ${e.message ?? "invalid"}`;
    })
    .join("; ");
}
