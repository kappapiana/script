#!/usr/bin/env python3

class Cobjects():
    '''Counts objects that start with a pattern + variable'''
    
    start = "variable_" # static variable
    def count_obj(self, letterona, values):
        '''passing the values and the letter'''
        total = 0
        count = 0
        for v in values:
            if v.startswith(Cobjects.start + letterona):
                total += values[v] # adds found value (supposedly 1 or 0)
                count += 1 # adds one to count
        return total, count

# hardwired values
# ======================
values = {
  "variable_a_1": 1,
  "variable_a_2": 1,
  "variable_a_3": 1,
  "variable_a_4": 1,
  "variable_b_1": 1,
  "variable_b_2": 1,
  "variable_b_3": 1,
  "variable_b_4": 1,
  "variable_b_5": 1,
  "variable_c_1": 1,
  "variable_c_2": 1,
  "model": "Mustang",
}
# ======================

def check_step(question_10="Sì", question_14="Sì"):
    '''Checks if we go to step 1 or 2
    adds further letters to the list of checked variables'''
    
    active = []
    if question_10 == "Sì":
        active = ["b"]
        if question_14 == "Sì":
            active = active + ["c"]
    print(active)
    return active

def count(letters, values):
    count_result = []
    print(letters)
    for i in letters:
        count_result.append(Cobjects().count_obj(i, values))

    return count_result

def main():
    active_fields = ["a"] # non optional
    active_fields = active_fields + check_step()

    result = count(active_fields, values)

    sums_values = sum(i for i, j in result)
    sums_entries = sum(j for i, j in result)
    score = sums_values / sums_entries * 100

    # output

    print(sums_values, sums_entries)
    print("score is: ", score, "%")

if __name__ == '__main__':
    main()
