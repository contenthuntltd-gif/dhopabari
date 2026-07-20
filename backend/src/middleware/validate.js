/**
 * Validates req.body against a Zod schema. On failure, responds 400 with
 * a readable list of field errors instead of reaching the controller.
 */
function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({
        ok: false,
        error: 'Validation failed',
        details: result.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
      });
      return;
    }
    req.body = result.data;
    next();
  };
}

module.exports = { validate };
