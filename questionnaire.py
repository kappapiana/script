#!/usr/bin/env python3

class Cobjects():
    '''Counts objects that matches a pattern'''
    
    start = "variable_" # static variable

    def count_obj(self, letterona, values):
        '''passing the values and the letter'''
        total = 0
        count = 0
        for v in values:
            if v.startswith(Cobjects.start + letterona):
                total += values[v]
                count += 1
        return total, count

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
  "model": "Mustang",
  "year": 1964
}

def check_step(question_10="Sì", question_14="Sì", values=None):
    '''Checks if we go to step 1 or 2'''
    active = []
    if question_10 == "Sì":
        active = ["b"]
        if question_14 == "Sì":
            active = active + ["c"]
    print(active)
    return active

def count(letters, values):
    count_result = []
    for i in letters:
        count_result.append(Cobjects().count_obj("a", values))

    return count_result

def main():
    active_fields = ["a"]
    print(active_fields)
    active_fields = active_fields + check_step(values=values)
    print(active_fields)

    result = count(active_fields, values)

    sums_values = sum(i for i, j in result)
    sums_counts = sum(j for i, j in result)
    score = sums_values / sums_counts * 100

    print(sums_values, sums_counts)
    print("score is: ", score, "%")

if __name__ == '__main__':
    main()
