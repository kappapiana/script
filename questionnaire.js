class Cobjects {
    // Counts objects that start with a pattern + variable
    static start = "variable_"; // static variable
    
    countObj(letterona, values) {
        // passing the values and the letter
        let total = 0;
        let count = 0;

        for (const v in values) {
            if (values.hasOwnProperty(v) && v.startsWith(Cobjects.start + letterona)) {
                total += values[v]; // adds found value (supposedly 1 or 0)
                count += 1; // adds one to count
            }
        }

        return [total, count];
    }
}

// hardwired values
// ======================
const values = {
    "variable_a_1": 0,
    "variable_a_2": 1,
    "variable_a_3": 0,
    "variable_a_4": 1,
    "variable_b_1": 1,
    "variable_b_2": 1,
    "variable_b_3": 1,
    "variable_b_4": 1,
    "variable_b_5": 1,
    "variable_c_1": 1,
    "variable_c_2": 0,
    "model": "Mustang",
    "year": 1964
};
// ======================

function checkStep(question10 = "Sì", question14 = "Sì") {
    // Checks if we go to step 1 or 2
    // adds further letters to the list of checked variables
    const active = [];

    if (question10 === "Sì") {
        active.push("b");

        if (question14 === "Sì") {
            active.push("c");
        }
    }

    console.log(active);
    return active;
}

function count(letters, values) {
    const countResult = [];

    for (const letter of letters) {
        countResult.push(new Cobjects().countObj(letter, values));
    }

    return countResult;
}

function main() {
    let activeFields = ["a"]; // non-optional
    activeFields = activeFields.concat(checkStep());

    const result = count(activeFields, values);

    const sumsValues = result.reduce((sum, [i, j]) => sum + i, 0);
    const sumsEntries = result.reduce((sum, [i, j]) => sum + j, 0);
    const score = (sumsValues / sumsEntries) * 100;

    // output
    console.log(sumsValues, sumsEntries);
    console.log("score is: ", score, "%");
}

main();
