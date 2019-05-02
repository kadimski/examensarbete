# examensarbete
<h1>Canvas LMS tools for bachelor thesis</h1>

These Canvas LMS tools were created for a bachelor thesis associated with Professor Gerald Q. "Chip" Maguire Jr. (https://github.com/gqmaguirejr). The tools have been tested against a VM running a Canvas domain.

<h3>create_required_group_sets.rb</h3>

This script is only a helper script to create the required group sets in order to get <b>grade_discussing_users.rb</b>, <b>group_users_to_AL.rb</b> and <b>s-announce-presentation.rb</b> working properly for testing and demonstration.


<h3>example_config.json</h3>

This is an example config.json file for use with the scripts.

<h3>grade_discussing_users.rb</h3>

This script grades each participant in a discussion with the grade <i>pass</i>, otherwise <i>fail</i>. This script is thought to be used in a cron job.

<h3>group_users_to_AL.rb</h3>

This script groups users from two different group sets to a single one.

<h3>prototype_1.rb</h3>

This script is only a prototype which has been used for learning and testing and is of no value.

<h3>s-announce-presentation.rb</h3>

This script is a follow up on Prof. Maguire's version with added functionality. When an announcement is created three groups are created in three different group sets with preconfigured group names.
