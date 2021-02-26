defmodule MiataBotWeb.MailController do
  use MiataBotWeb, :controller
  require Logger

  %{
    "SPF" => "pass",
    "attachments" => "0",
    "charsets" => "{\"to\":\"UTF-8\",\"html\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\",\"text\":\"UTF-8\"}",
    "dkim" => "{@gmail.com : pass}",
    "envelope" => "{\"to\":[\"miata-bot@miata-bot.sixtyeightplus.one\"],\"from\":\"konnorrigby@gmail.com\"}",
    "from" => "Connor Rigby <konnorrigby@gmail.com>",
    "headers" => "Received: by mx0084p1las1.sendgrid.net with SMTP id iXpfTZPWS5 Fri, 26 Feb 2021 03:13:40 +0000 (UTC)\nReceived: from mail-oi1-f175.google.com (unknown [209.85.167.175]) by mx0084p1las1.sendgrid.net (Postfix) with ESMTPS id D05B8921064 for <miata-bot@miata-bot.sixtyeightplus.one>; Fri, 26 Feb 2021 03:13:40 +0000 (UTC)\nReceived: by mail-oi1-f175.google.com with SMTP id a13so8420478oid.0 for <miata-bot@miata-bot.sixtyeightplus.one>; Thu, 25 Feb 2021 19:13:40 -0800 (PST)\nDKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=gmail.com; s=20161025; h=mime-version:from:date:message-id:subject:to; bh=tVElWshUMBMUABpeJ7RZKlD+DpsgIXyyZ2sSwhqPqqY=; b=tDm6MHTQ4eIQbWTr703lF+jxyZU0TT8aYrqDuBhpZEalFbh5Yv0nvcBlq0etFwDHQx tfoQGv76Iz1GRASMN/cyrqjW7LBvaJT4cuO4R8yOzRstEJECWGETCoPXXXg2JSc4WNoQ 53RBlaGiCHlMmzun9p0JKCJ5Lv9sOVJIUYXPFMEGb/GNoupjjh4HwE5FcZkjkDTrFfw7 w9Efchs8u1638pp/+6EsC+CgxsgjhKlK7vP1BzVjw5YXiTzUSto9mtpWPu6W+aPermEK FrYxs4XOh3uBykly5MLvJklAH3QbEyNCG9+xT9+5eKqt68KLb/VSYG1EiplsJVuf3nnR A8HA==\nX-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=1e100.net; s=20161025; h=x-gm-message-state:mime-version:from:date:message-id:subject:to; bh=tVElWshUMBMUABpeJ7RZKlD+DpsgIXyyZ2sSwhqPqqY=; b=LwcOC4VYDGQQVzhEsB2Buqb0BskPwi7RQSJkso2FqL5lCzrIxDNq53aIAecCulUvW+ sdQzBexxFw+keGc5YMdFt3RDNx9RQ5NhkI/peLcfnwwLRlwue6ib/0b1C0vduqpscdt2 WrYtDHHWyQS1ciHiJi7rGe1uSLJ4QfJdUjiXvrmJHepijaz02CBtf5bvT7cwUh48kIRO efHleMLibAetCCU15LxEYvzUjzDQeaw+0Yt3xDxXrC/Z9nMNEg2ZxDDSsy+GPAm6/EPd K6t3GFmDz+oqWyWdUf4kG1PVFDbc3UfThRKkR1Kbzny7j8tjYYwjFSxia+ELs2po4LPo kj5Q==\nX-Gm-Message-State: AOAM531xriuijp/kL1xCB2uMVWrueiTa3VCFPOBKy0KE1KK5J+dpWTp3 udOnynMnDVPDrE58RTk/SXFjhMtm5ZFT6LsVwftjJut19GQ=\nX-Google-Smtp-Source: ABdhPJwVIK00OWdqpP4RTNiBh4zV9IoqRE8mMSXY2KtulG2T3wpa+NPsjYzSF9zNCvfSTwPeeNkcuMoRF81cOZailnc=\nX-Received: by 2002:aca:b744:: with SMTP id h65mr665723oif.36.1614309220181; Thu, 25 Feb 2021 19:13:40 -0800 (PST)\nMIME-Version: 1.0\nFrom: Connor Rigby <konnorrigby@gmail.com>\nDate: Thu, 25 Feb 2021 19:13:29 -0800\nMessage-ID: <CABT61E5X457zgz-ovf9BRhOHif2aMesLjTwJx7hw3t4XVnKDRA@mail.gmail.com>\nSubject: hello\nTo: miata-bot@miata-bot.sixtyeightplus.one\nContent-Type: multipart/alternative; boundary=\"000000000000a06bcd05bc34a771\"\n",
    "html" => "<div dir=\"ltr\">word<br></div>\n",
    "sender_ip" => "209.85.167.175",
    "spam_report" => "Spam detection software, running on the system \"mx0084p1las1.sendgrid.net\",\nhas NOT identified this incoming email as spam.  The original\nmessage has been attached to this so you can view it or label\nsimilar future email.  If you have any questions, see\n@@CONTACT_ADDRESS@@ for details.\n\nContent preview:  word word \n\nContent analysis details:   (0.0 points, 5.0 required)\n\n pts rule name              description\n---- ---------------------- --------------------------------------------------\n 0.0 FREEMAIL_FROM          Sender email is commonly abused enduser mail\n                            provider\n                            [konnorrigby[at]gmail.com]\n\n",
    "spam_score" => "0.001",
    "subject" => "hello",
    "text" => "word\n",
    "to" => "miata-bot@miata-bot.sixtyeightplus.one"
  }



  def mail(conn, params) do
    Logger.info("incoming email #{inspect(params)}")

    conn
    |> send_resp(200, "")
  end
end
