#!/usr/bin/env python3

import sys, re

# this variable handles the maximum number of lines expected
max_count = 0
# this variable keeps track of lines processed
count = 0
# this variable stores Valid/Invalid values
cc_numbers = []

# this regex matches numbers that start with 4-6, are either a single 16 digit number or 4 sets of 4 digit numbers separated by only '-'
v_reg = re.compile(r'^([4-6](\d){15}|[4-6][0-9]{3}(-[0-9]{4}){3})$')
# this regex matches numbers that have 4 or more consecutive repeating digits
repeat_reg = re.compile(r'[0-9]*(\d)\1{3,}[0-9]*')

# for loop to process stdin, enumeration to get line count with value
for each in enumerate(sys.stdin):
    # if line number is 0 and value is an integer proceed
    if each[0] == 0 and float(each[1]).is_integer():
        # if value is greater than 0 and less than 100 proceed
        if int(each[1]) > 0 and int(each[1]) < 100:
            max_count = int(each[1])
        else:
            # raise error if value of line 0 does not fall within specified values
            raise ValueError("First line of input must be greater than 0 and less than 100. Input value was: " + each[1].rstrip())
    # if line number is 0 and value is not an integer notify user
    elif each[0] == 0 and not float(each[1]).is_integer():
        raise ValueError("First line of input is a non-integer.")
    else:
        # if value matches v_reg regex expression then proceed
        if v_reg.match(each[1].rstrip()):
            # strip out '-' characters and check for 4 or more consecutive repeating digits and proceed if none are found
            if not repeat_reg.match(each[1].rstrip().replace('-', '')):
                cc_numbers.append('Valid')
            else:
                cc_numbers.append('Invalid')
        else:
            cc_numbers.append('Invalid')
    # increment count variable
    count += 1
    # compare count to max_count and break out of loop if count is greater
    if count > max_count:
      break

# print Valid/Invalid array.
for value in cc_numbers:
  print(value)
