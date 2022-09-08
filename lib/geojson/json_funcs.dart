
getJSON(name) {
  return JSON.parse(fs.readFileSync(path.join(__dirname, `/fixtures/${  name}`)));
}