module SkeletonHelper
  def skeleton_loader(type: :text, count: 1)
    render "components/skeleton", type: type.to_s, count: count
  end
end
