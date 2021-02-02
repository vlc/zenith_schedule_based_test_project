require 'dyrt\OtDyrt.rb'
require 'dyrt\OtDyrtForm.rb'

if $DYRT.nil?
  $DYRT = OtDyrt.new
  # $DYRT.init
end

$DYRT.exportToDyrt
