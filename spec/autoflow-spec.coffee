describe "Autoflow package", ->
  [autoflow, editor, editorElement] = []

  describe "autoflow:reflow-selection", ->
    beforeEach ->
      activationPromise = null

      waitsForPromise ->
        atom.workspace.open()

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editorElement = atom.views.getView(editor)

        atom.config.set('editor.preferredLineLength', 30)

        activationPromise = atom.packages.activatePackage('autoflow')

        atom.commands.dispatch editorElement, 'autoflow:reflow-selection'

      waitsForPromise ->
        activationPromise

    it "uses the preferred line length based on the editor's scope", ->
      atom.config.set('editor.preferredLineLength', 4, scopeSelector: '.text.plain.null-grammar')
      editor.setText("foo bar")
      editor.selectAll()
      atom.commands.dispatch editorElement, 'autoflow:reflow-selection'

      expect(editor.getText()).toBe """
        foo
        bar
      """

    it "rearranges line breaks in the current selection to ensure lines are shorter than config.editor.preferredLineLength", ->
      editor.setText """
        This is the first paragraph and it is longer than the preferred line length so it should be reflowed.

        This is a short paragraph.

        Another long paragraph, it should also be reflowed with the use of this single command.
      """

      editor.selectAll()
      atom.commands.dispatch editorElement, 'autoflow:reflow-selection'

      expect(editor.getText()).toBe """
        This is the first paragraph
        and it is longer than the
        preferred line length so it
        should be reflowed.

        This is a short paragraph.

        Another long paragraph, it
        should also be reflowed with
        the use of this single
        command.
      """

    it "reflows the current paragraph if nothing is selected", ->
      editor.setText """
        This is a preceding paragraph, which shouldn't be modified by a reflow of the following paragraph.

        The quick brown fox jumps over the lazy
        dog. The preceding sentence contains every letter
        in the entire English alphabet, which has absolutely no relevance
        to this test.

        This is a following paragraph, which shouldn't be modified by a reflow of the preciding paragraph.

      """

      editor.setCursorBufferPosition([3, 5])
      atom.commands.dispatch editorElement, 'autoflow:reflow-selection'

      expect(editor.getText()).toBe """
        This is a preceding paragraph, which shouldn't be modified by a reflow of the following paragraph.

        The quick brown fox jumps over
        the lazy dog. The preceding
        sentence contains every letter
        in the entire English
        alphabet, which has absolutely
        no relevance to this test.

        This is a following paragraph, which shouldn't be modified by a reflow of the preciding paragraph.

      """

    it "allows for single words that exceed the preferred wrap column length", ->
      editor.setText("this-is-a-super-long-word-that-shouldn't-break-autoflow and these are some smaller words")

      editor.selectAll()
      atom.commands.dispatch editorElement, 'autoflow:reflow-selection'

      expect(editor.getText()).toBe """
        this-is-a-super-long-word-that-shouldn't-break-autoflow
        and these are some smaller
        words
      """

  describe "reflowing text", ->
    beforeEach ->
      autoflow = require("../lib/autoflow")

    it 'respects current paragraphs', ->
      text = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh id magna ullamcorper sagittis. Maecenas
        et enim eu orci tincidunt adipiscing
        aliquam ligula.

        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Phasellus gravida
        nibh id magna ullamcorper
        tincidunt adipiscing lacinia a dui. Etiam quis erat dolor.
        rutrum nisl fermentum rhoncus. Duis blandit ligula facilisis fermentum.
      '''

      res = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh
        id magna ullamcorper sagittis. Maecenas et enim eu orci tincidunt adipiscing
        aliquam ligula.

        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh
        id magna ullamcorper tincidunt adipiscing lacinia a dui. Etiam quis erat dolor.
        rutrum nisl fermentum rhoncus. Duis blandit ligula facilisis fermentum.
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res

    it 'respects indentation', ->
      text = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh id magna ullamcorper sagittis. Maecenas
        et enim eu orci tincidunt adipiscing
        aliquam ligula.

            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
            Phasellus gravida
            nibh id magna ullamcorper
            tincidunt adipiscing lacinia a dui. Etiam quis erat dolor.
            rutrum nisl fermentum  rhoncus. Duis blandit ligula facilisis fermentum
      '''

      res = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh
        id magna ullamcorper sagittis. Maecenas et enim eu orci tincidunt adipiscing
        aliquam ligula.

            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida
            nibh id magna ullamcorper tincidunt adipiscing lacinia a dui. Etiam quis
            erat dolor. rutrum nisl fermentum  rhoncus. Duis blandit ligula facilisis
            fermentum
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res

    it 'respects prefixed text (comments!)', ->
      text = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh id magna ullamcorper sagittis. Maecenas
        et enim eu orci tincidunt adipiscing
        aliquam ligula.

          #  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
          #  Phasellus gravida
          #  nibh id magna ullamcorper
          #  tincidunt adipiscing lacinia a dui. Etiam quis erat dolor.
          #  rutrum nisl fermentum  rhoncus. Duis blandit ligula facilisis fermentum
      '''

      res = '''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida nibh
        id magna ullamcorper sagittis. Maecenas et enim eu orci tincidunt adipiscing
        aliquam ligula.

          #  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida
          #  nibh id magna ullamcorper tincidunt adipiscing lacinia a dui. Etiam quis
          #  erat dolor. rutrum nisl fermentum  rhoncus. Duis blandit ligula facilisis
          #  fermentum
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res

    it 'respects multiple prefixes (js/c comments)', ->
      text = '''
        // Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida
        et enim eu orci tincidunt adipiscing
        aliquam ligula.
      '''

      res = '''
        // Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida et
        // enim eu orci tincidunt adipiscing aliquam ligula.
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res

    it 'properly handles * prefix', ->
      text = '''
        * Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida
        et enim eu orci tincidunt adipiscing
        aliquam ligula.

          * soidjfiojsoidj foi
      '''

      res = '''
        * Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus gravida et
        * enim eu orci tincidunt adipiscing aliquam ligula.

          * soidjfiojsoidj foi
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res
    it 'handles different initial indentation', ->
      text = '''
        Magna ea magna fugiat nisi minim in id duis. Culpa sit sint consequat quis elit magna pariatur incididunt
          proident laborum deserunt est aliqua reprehenderit. Occaecat et ex non do Lorem irure adipisicing mollit excepteur
          eu ullamco consectetur. Ex ex Lorem duis labore quis ad exercitation elit dolor non adipisicing. Pariatur commodo ullamco
          culpa dolor sunt enim. Ullamco dolore do ea nulla ut commodo minim consequat cillum ad velit quis.
      '''
      
      res = '''
        Magna ea magna fugiat nisi minim in id duis. Culpa sit sint consequat quis elit
        magna pariatur incididunt proident laborum deserunt est aliqua reprehenderit.
        Occaecat et ex non do Lorem irure adipisicing mollit excepteur eu ullamco
        consectetur. Ex ex Lorem duis labore quis ad exercitation elit dolor non
        adipisicing. Pariatur commodo ullamco culpa dolor sunt enim. Ullamco dolore do
        ea nulla ut commodo minim consequat cillum ad velit quis.
      '''
      expect(autoflow.reflow(text, wrapColumn: 80)).toEqual res
