require 'test_helper'

class OutputRunnerWithExceptionNotificationTest < Whenever::TestCase
  test "is wrapped with Exception Notifier" do
    output = Whenever.cron \
      <<-file
        set :job_template, nil
        set :path, '/your/path'
        set :runner_exception_notification, true
        every :day do
          runner "Worker.do"
        end
      file

    assert_match %(0 0 * * * cd /your/path && bundle exec script/runner -e production 'begin; Worker.do; rescue => e; ExceptionNotifier.notify_exception(e); raise e; end'), output
  end

  test "single runner is wrapped with Exception Notifier" do
    output = Whenever.cron \
      <<-file
        set :job_template, nil
        set :path, '/your/path'
        every :day do
          runner "Worker.do", runner_exception_notification: true
        end
      file

    assert_match %(0 0 * * * cd /your/path && bundle exec script/runner -e production 'begin; Worker.do; rescue => e; ExceptionNotifier.notify_exception(e); raise e; end'), output
  end
end
