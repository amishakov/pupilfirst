type status = {
  passedAt: option(Js.Date.t),
  feedbackSent: bool,
};

type t = {
  id: string,
  title: string,
  createdAt: Js.Date.t,
  levelId: string,
  userNames: string,
  status: option(status),
  coachIds: array(string),
};

let id = t => t.id;
let title = t => t.title;
let levelId = t => t.levelId;
let userNames = t => t.userNames;
let coachIds = t => t.coachIds;

let failed = t =>
  switch (t.status) {
  | None => false
  | Some(status) =>
    status.passedAt |> OptionUtils.mapWithDefault(_ => false, true)
  };

let pendingReview = t =>
  t.status |> OptionUtils.mapWithDefault(_ => false, true);

let feedbackSent = t =>
  t.status |> OptionUtils.mapWithDefault(status => status.feedbackSent, false);

let createdAtPretty = t => t.createdAt->DateFns2.format("MMMM D, YYYY");

let timeDistance = t =>
  t.createdAt
  ->DateFns2.formatDistanceToNowStrictOpt(
      DateFns2.formatDistanceStrictOptions(~addSuffix=true, ()),
    );

let sortArray = (sortDirection, submissions) => {
  let sortDescending =
    submissions
    |> ArrayUtils.copyAndSort((x, y) =>
         DateFns2.differenceInSeconds(y.createdAt, x.createdAt)
       );
  switch (sortDirection) {
  | `Descending => sortDescending
  | `Ascending => sortDescending |> Js.Array.reverseInPlace
  };
};

let make = (~id, ~title, ~createdAt, ~levelId, ~userNames, ~status, ~coachIds) => {
  id,
  title,
  createdAt,
  levelId,
  userNames,
  status,
  coachIds,
};

let makeStatus = (~passedAt, ~feedbackSent) => {passedAt, feedbackSent};

let decodeJs = details =>
  details
  |> Js.Array.map(s =>
       switch (s) {
       | Some(submission) =>
         let status =
           submission##evaluatedAt
           ->Belt.Option.map(_ =>
               makeStatus(
                 ~passedAt=
                   submission##passedAt->Belt.Option.map(DateFns2.parseJson),
                 ~feedbackSent=submission##feedbackSent,
               )
             );

         [
           make(
             ~id=submission##id,
             ~title=submission##title,
             ~createdAt=DateFns2.parseJson(submission##createdAt),
             ~levelId=submission##levelId,
             ~userNames=submission##userNames,
             ~status,
             ~coachIds=submission##coachIds,
           ),
         ];
       | None => []
       }
     );

let replace = (e, l) => l |> Array.map(s => s.id == e.id ? e : s);

let statusEq = (overlaySubmission, t) =>
  switch (
    t.status,
    overlaySubmission |> CoursesReview__OverlaySubmission.evaluatedAt,
  ) {
  | (None, None) => true
  | (Some({passedAt}), Some(_)) =>
    passedAt == CoursesReview__OverlaySubmission.passedAt(overlaySubmission)
  | (Some(_), None)
  | (None, Some(_)) => false
  };
