// Licensed under GPL-3.0. See LICENSE.
//
//  PageSession+Blockable.swift
//  LeleleBrowser
//
//  PageSession satisfies LeleleBrowserBlocker's page seam as-is: itemID, isOAuthFlow and
//  webView are already its own stored properties. Task 6 moves this into LeleleBrowserWeb.
//

import LeleleBrowserBlocker

extension PageSession: BlockablePage {}
