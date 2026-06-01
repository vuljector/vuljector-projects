async function trigger() {
  let a = 1;
  await Promise.resolve();
  return a;
}

async function main() {
  for (let i = 0; i < 1000; i++) {
    await trigger();
  }
}
main();
