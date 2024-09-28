import { assert } from "jsr:@std/assert";
import { delay } from "jsr:@std/async";
assert(Deno.args.length === 3, "Usage: deno run test.ts <image> <command> <args>");

while (true) {
    await delay(5000);

    const response = new Deno.Command("/usr/bin/docker", {
        args: [
            "pull",
            Deno.args[ 0 ]
        ],
        stderr: "piped",
        stdout: "piped"
    });

    const output = await response.output();


    const error = await new Response(output.stderr).text();
    assert(!error, error);

    const text = await new Response(output.stdout).text();

    if (text.includes("Image is up to date")) {
        continue;
    }

    console.log("Image updated");

    await new Deno.Command(Deno.args[ 1 ], {
        args: Deno.args[ 2 ].split(" ")
    }).output();
}