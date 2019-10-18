/* :folding=explicit:collapseFolds=1: */

/*
 * $Id$
 *
 * Copyright (C) 2004 Slava Pestov.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * DEVELOPERS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package factor;

import java.util.Iterator;
import java.util.Set;

public interface VocabularyLookup
{
	public FactorWord define(String in, String word)
		throws Exception;

	public FactorWord searchVocabulary(Cons use, String word)
		throws Exception;

	public void forget(FactorWord word);

	/**
	 * @param use A list of vocabularies.
	 * @param word A substring of the word name to complete
	 * @param anywhere If true, matches anywhere in the word name are
	 * returned; otherwise, only matches from beginning.
	 * @param completions Set to add completions to
	 */
	public void getWordCompletions(Cons use, String word, boolean anywhere,
		Set completions) throws Exception;

	/**
	 * @param vocab A string to complete
	 * @param anywhere If true, matches anywhere in the vocab name are
	 * returned; otherwise, only matches from beginning.
	 */
	public String[] getVocabCompletions(String vocab, boolean anywhere)
		throws Exception;

	/**
	 * @param vocab The vocabulary name
	 * @param word A substring of the word name to complete
	 * @param anywhere If true, word name will be matched anywhere, otherwise, just at
	 * the beginning of the name.
	 * @param completions Set to add completions to
	 */
	public void getWordCompletions(String vocab, String word, boolean anywhere,
		Set completions) throws Exception;

	public Cons getVocabularies() throws Exception;
}