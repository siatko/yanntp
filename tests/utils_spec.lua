local utils = require("yanntp.utils")

describe("slugify_title", function()
  it("lowercases input", function()
    assert.equal("hello", utils.slugify_title("Hello"))
  end)

  it("replaces spaces with hyphens", function()
    assert.equal("hello-world", utils.slugify_title("hello world"))
  end)

  it("collapses multiple spaces", function()
    assert.equal("hello-world", utils.slugify_title("hello   world"))
  end)

  it("removes special characters", function()
    assert.equal("hello-world", utils.slugify_title("hello, world!"))
  end)

  it("strips leading and trailing hyphens", function()
    assert.equal("hello", utils.slugify_title("-hello-"))
  end)

  it("collapses multiple hyphens", function()
    assert.equal("hello-world", utils.slugify_title("hello--world"))
  end)

  it("handles mixed case and symbols", function()
    assert.equal("fix-login-bug", utils.slugify_title("Fix Login Bug!"))
  end)
end)

describe("slugify_tag", function()
  it("lowercases input", function()
    assert.equal("lua", utils.slugify_tag("Lua"))
  end)

  it("replaces spaces with underscores", function()
    assert.equal("my_tag", utils.slugify_tag("my tag"))
  end)

  it("replaces hyphens with underscores", function()
    assert.equal("my_tag", utils.slugify_tag("my-tag"))
  end)

  it("collapses multiple underscores", function()
    assert.equal("my_tag", utils.slugify_tag("my__tag"))
  end)

  it("removes special characters", function()
    assert.equal("mytag", utils.slugify_tag("my@tag!"))
  end)

  it("strips leading and trailing underscores", function()
    assert.equal("tag", utils.slugify_tag("_tag_"))
  end)
end)

describe("tags_from_filename", function()
  it("returns empty table when no tags", function()
    assert.same({}, utils.tags_from_filename("20260514--my-note.md"))
  end)

  it("returns single tag", function()
    assert.same({ "lua" }, utils.tags_from_filename("20260514--my-note__lua.md"))
  end)

  it("returns multiple tags", function()
    assert.same({ "pkm", "writing" }, utils.tags_from_filename("20260514--my-note__pkm_writing.md"))
  end)

  it("handles todo filenames", function()
    assert.same({ "backend" }, utils.tags_from_filename("20260514-O-fix-bug__backend.md"))
  end)

  it("returns empty table for filename with no extension match", function()
    assert.same({}, utils.tags_from_filename("notanotefile.txt"))
  end)
end)

describe("relative_path", function()
  it("same directory", function()
    assert.equal("note.md", utils.relative_path("/notes/inbox", "/notes/inbox/note.md"))
  end)

  it("sibling directory", function()
    assert.equal("../zettel/note.md", utils.relative_path("/notes/inbox", "/notes/zettel/note.md"))
  end)

  it("parent to child", function()
    assert.equal("inbox/note.md", utils.relative_path("/notes", "/notes/inbox/note.md"))
  end)

  it("child to parent", function()
    assert.equal("../note.md", utils.relative_path("/notes/inbox", "/notes/note.md"))
  end)

  it("deeply nested sibling", function()
    assert.equal("../../b/c/note.md", utils.relative_path("/a/x/y", "/a/b/c/note.md"))
  end)
end)
