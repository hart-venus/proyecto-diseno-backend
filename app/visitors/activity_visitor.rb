class ActivityVisitor
  def visit(activity)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end