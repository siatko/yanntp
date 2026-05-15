local utils = require("denim.utils")

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

describe("rename_tag_in_filename", function()
  it("renames a single tag", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__foo.md", "foo", "bar")
    assert.is_true(ok)
    assert.equal("20260101--note__bar.md", f)
  end)

  it("renames one tag among many, keeps others sorted", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__apple_foo_zebra.md", "foo", "mango")
    assert.is_true(ok)
    assert.equal("20260101--note__apple_mango_zebra.md", f)
  end)

  it("returns false when tag is not present", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__foo.md", "bar", "baz")
    assert.is_false(ok)
    assert.equal("20260101--note__foo.md", f)
  end)

  it("returns false for filename with no tags", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note.md", "foo", "bar")
    assert.is_false(ok)
    assert.equal("20260101--note.md", f)
  end)

  it("removes tag when new_tag is empty string", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__foo_bar.md", "foo", "")
    assert.is_true(ok)
    assert.equal("20260101--note__bar.md", f)
  end)

  it("drops tag section entirely when last tag is removed", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__foo.md", "foo", "")
    assert.is_true(ok)
    assert.equal("20260101--note.md", f)
  end)

  it("deduplicates when new tag already exists", function()
    local f, ok = utils.rename_tag_in_filename("20260101--note__bar_foo.md", "foo", "bar")
    assert.is_true(ok)
    assert.equal("20260101--note__bar.md", f)
  end)

  it("works with todo filenames", function()
    local f, ok = utils.rename_tag_in_filename("20260101-O-fix-bug__backend_foo.md", "foo", "ops")
    assert.is_true(ok)
    assert.equal("20260101-O-fix-bug__backend_ops.md", f)
  end)
end)

describe("resolve_slug", function()
  it("preserves current slug when name is empty", function()
    assert.equal("my-note", utils.resolve_slug("", "My Note", "my-note"))
  end)

  it("preserves current slug when name matches title exactly", function()
    assert.equal("my-note", utils.resolve_slug("My Note", "My Note", "my-note"))
  end)

  it("preserves current slug when name matches title in different case", function()
    assert.equal("my-note", utils.resolve_slug("my note", "My Note", "my-note"))
  end)

  it("preserves current slug when name is lowercase of title (default prompt value)", function()
    assert.equal("my-note", utils.resolve_slug("my note", "My Note", "my-note"))
  end)

  it("slugifies new name when it differs from current title", function()
    assert.equal("new-name", utils.resolve_slug("New Name", "My Note", "my-note"))
  end)

  it("slugifies new name when only partially matching title", function()
    assert.equal("my-note-updated", utils.resolve_slug("My Note Updated", "My Note", "my-note"))
  end)
end)

describe("find_link_path", function()
  local line = "see [Alpha](alpha.md) and [Beta](beta.md) for details"

  it("returns path when cursor is on link text", function()
    assert.equal("alpha.md", utils.find_link_path(line, 6))
  end)

  it("returns path when cursor is on link url", function()
    assert.equal("alpha.md", utils.find_link_path(line, 16))
  end)

  it("returns path when cursor is on closing paren", function()
    assert.equal("alpha.md", utils.find_link_path(line, 21))
  end)

  it("returns nearest link when cursor is before all links", function()
    assert.equal("alpha.md", utils.find_link_path(line, 1))
  end)

  it("returns nearest link when cursor is after all links", function()
    assert.equal("beta.md", utils.find_link_path(line, #line))
  end)

  it("returns nearest link when cursor is between two links", function()
    -- cursor at 'a' in 'and', closer to Beta
    assert.equal("beta.md", utils.find_link_path(line, 27))
  end)

  it("returns nil when line has no links", function()
    assert.is_nil(utils.find_link_path("no links here", 1))
  end)

  it("returns the only link on a line regardless of cursor position", function()
    assert.equal("note.md", utils.find_link_path("- [ ] [My Note](note.md)", 1))
    assert.equal("note.md", utils.find_link_path("- [ ] [My Note](note.md)", 3))
  end)
end)
