class QuestionsController < ApplicationController
  before_action :load_question, only: [:show, :edit, :update, :destroy]

  before_action :authorize_user, except: [:create]
  # GET /questions/1/edit
  def edit
  end

  # POST /questions
  def create
    @question = Question.new(question_params)

    @question.author = current_user

    if check_captcha(@question) && @question.save
      redirect_to user_path(@question.user), notice: "Вопрос задан"
    else
      redirect_to user_path(@question.user), alert: "Не введен вопрос/не выполнена проверка на бота"
    end
  end

  # PATCH/PUT /questions/1
  def update
    if @question.update(question_params)
      redirect_to user_path(@question.user), notice: 'Вопрос сохранен'
    else
      render :edit
    end
  end

  # DELETE /questions/1
  def destroy
    user = @question.user
    @question.destroy

    redirect_to user_path(user), notice: "Вопрос удален"
  end

  private

  def authorize_user
    reject_user unless @question.user == current_user
  end

  # Use callbacks to share common setup or constraints between actions.
  def load_question
    @question = Question.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def question_params
    if current_user.present? && params[:question][:user_id].to_i == current_user.id
      params.require(:question).permit(:user_id, :text, :answer)
    else
      params.require(:question).permit(:user_id, :text)
    end
  end

  def check_captcha(model)
    current_user.present? || verify_recaptcha(model: model)
  end
end
