class FinancialBaseController < ApplicationController
  layout "shell"

  class_attribute :permission_subject

  MODULE_SUBJECTS = {
    "Accounting" => :accounting,
    "Treasury" => :treasury,
    "Equity" => :share_capital,
    "Lending" => :loan
  }.freeze

  before_action :require_financial_permission

  private

  def require_financial_permission
    subject = self.class.permission_subject || inferred_subject
    return unless subject

    unless Management::PermissionService.authorized?(user: Current.user, action: params[:action], subject: subject, branch: Current.branch)
      redirect_to root_path, alert: "You are not permitted to perform this action."
    end
  end

  def inferred_subject
    mod = self.class.module_parent
    return unless mod.respond_to?(:name)

    if MODULE_SUBJECTS.key?(mod.name)
      return MODULE_SUBJECTS[mod.name]
    end

    parent = mod.module_parent
    if parent.respond_to?(:name) && parent.name != "Object"
      return MODULE_SUBJECTS[parent.name]
    end

    nil
  end
end
