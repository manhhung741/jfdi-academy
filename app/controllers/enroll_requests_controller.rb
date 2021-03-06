class EnrollRequestsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :enroll_request, through: :course

  before_filter :load_general_course_data, only: [:index, :new]

  def index
    # only staff should be able to access this page
    # here staff can approve student to enroll to a class
    @staff_requests = []
    @student_requests = []

    std_role = Role.find_by_name("student")
    @enroll_requests.each do |er|
      if er.role == std_role
        @student_requests << er
      else
        @staff_requests << er
      end
    end
  end

  def new
    if !current_user
      redirect_to new_user_session_path
    end
    @er = EnrollRequest.find_by_user_id_and_course_id(current_user.id, @course.id)
    if !curr_user_course.id && !@er
      if params[:role]
        @role = Role.find_by_name(params[:role])
      else
        @role = Role.find_by_name('student')
      end
      if @role == Role.shared.first
        authorize! :ask_for_share, Course
      end
      @enroll_request.course = @course
      @enroll_request.user = current_user
      @enroll_request.role = @role
      @enroll_request.save
      @er = @enroll_request
    end
  end

  def destroy
    if params[:approved]
      puts 'Request approved!'
      # create new UserCourse record
      uc = UserCourse.new
      uc.course = @enroll_request.course
      uc.user = @enroll_request.user
      uc.role = @enroll_request.role
      uc.exp = 0
      uc.save
      UserMailer.delay.new_student(uc.user, uc.course)
    end

    @enroll_request.destroy

    respond_to do |format|
      format.json { render json: { status: 'OK' } }
    end
  end
end
