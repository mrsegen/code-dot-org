require 'test_helper'

class Plc::EnrollmentModuleAssignmentTest < ActiveSupport::TestCase
  setup do
    course = create :plc_course
    @course_unit = create(:plc_course_unit, plc_course: course)
    learning_module = create(:plc_learning_module, plc_course_unit: @course_unit)
    @level1 = create(:external_link, url: 'some url')
    @level2 = create :maze
    @level3 = create :applab
    @level4 = create :external

    [@level1, @level2, @level3, @level4].each do |level|
      create(:script_level, script: @course_unit.script, stage: learning_module.stage, levels: [level])
    end

    @user = create :teacher
    user_course_enrollment = create(:plc_user_course_enrollment, user: @user, plc_course: course)
    @enrollment_unit_assignment = create(:plc_enrollment_unit_assignment, plc_user_course_enrollment: user_course_enrollment, plc_course_unit: @course_unit, user: @user)
    @enrollment_unit_assignment.enroll_user_in_unit_with_learning_modules([learning_module])
    @enrollment_unit_assignment.reload
  end

  test 'test module status reporting' do
    module_assignment = @enrollment_unit_assignment.plc_module_assignments.first

    assert_equal @user, module_assignment.user
    assert_equal Plc::EnrollmentModuleAssignment::NOT_STARTED, module_assignment.status

    User.track_level_progress_sync(user_id: @user.id,
                                   level_id: @level2.id,
                                   script_id: @course_unit.script.id,
                                   new_result: ActivityConstants::MINIMUM_PASS_RESULT,
                                   submitted: true,
                                   level_source_id: nil)
    assert_equal Plc::EnrollmentModuleAssignment::IN_PROGRESS, module_assignment.status

    User.track_level_progress_sync(user_id: @user.id,
                                   level_id: @level3.id,
                                   script_id: @course_unit.script.id,
                                   new_result: ActivityConstants::BEST_PASS_RESULT,
                                   submitted: true,
                                   level_source_id: nil)
    assert_equal Plc::EnrollmentModuleAssignment::COMPLETED, module_assignment.status
  end
end
