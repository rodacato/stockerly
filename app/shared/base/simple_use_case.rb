# Base class for use cases that don't need ApplicationUseCase's machinery
# (dry-monads, validate, publish). See ADR-006 for the decision matrix.
#
# Pure reads, single-resource mutations with a Rails-canonical 404 failure,
# and predicates inherit from this class. The base provides only `.call`
# delegation; the subclass's `#call` returns whatever shape fits — typically
# a raw ActiveRecord object, a scope, a hash, true/false, or nil.
class SimpleUseCase
  def self.call(...)
    new.call(...)
  end
end
