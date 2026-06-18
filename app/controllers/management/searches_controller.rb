module Management
  class SearchesController < BaseController
    def branches
      query = params[:q].to_s.strip
      @branches = query.present? ? Management::Branch.active.where("name ILIKE :q OR code ILIKE :q", q: "%#{query}%").limit(10) : Management::Branch.active.limit(10)
      render partial: "management/searches/branches", locals: { branches: @branches }
    end

    def users
      query = params[:q].to_s.strip
      @users = query.present? ? User.where("email_address ILIKE :q", q: "%#{query}%").limit(10) : User.none
      render partial: "management/searches/users", locals: { users: @users }
    end
  end
end
